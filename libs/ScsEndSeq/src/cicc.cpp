
#include <llvm/Constants.h>
#include <llvm/Instructions.h>
#include <llvm/LLVMContext.h>
#include <llvm/Module.h>
#include "llvm/PassManager.h"
#include <llvm/Bitcode/ReaderWriter.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/raw_ostream.h>
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "/usr/local/cuda/nvvm/include/nvvm.h"

#include <dlfcn.h>
#include <iostream>
#include <cstdio>
#include <list>
#include <string>
#include <sstream>
#include <vector>
#include <stack>
#include <map>
#include <fstream>

using namespace llvm;
using namespace std;


#define LIBNVVM "libnvvm.so"

static void* libnvvm = NULL;

#define bind_lib(lib) \
	if (!libnvvm) \
{ \
	libnvvm = dlopen(lib, RTLD_NOW | RTLD_GLOBAL); \
	if (!libnvvm) \
	{ \
		fprintf(stderr, "Error loading %s: %s\n", lib, dlerror()); \
		abort(); \
	} \
}

#define bind_sym(handle, sym, retty, ...) \
	typedef retty (*sym##_func_t)(__VA_ARGS__); \
static sym##_func_t sym##_real = NULL; \
if (!sym##_real) \
{ \
	sym##_real = (sym##_func_t)dlsym(handle, #sym); \
	if (!sym##_real) \
	{ \
		fprintf(stderr, "Error loading %s: %s\n", #sym, dlerror()); \
		abort(); \
	} \
}

std::vector<Value*> visitedInstVector;

static Module* initial_module = NULL;

/////////////////////////////////////////////////////////////

static long bambooIndex = 1;

static void writeIrToFile(Module* module, const char* filePath) {
    //errs() << "Dumping IR file ... \n";
    string err = "";
    raw_fd_ostream outputStream(filePath, err, 0);
    WriteBitcodeToFile(module, outputStream);
    outputStream.flush();
}

static void indexInstruction(Instruction* BI) {
    LLVMContext& C = BI->getContext();
    stringstream biString;
    biString << bambooIndex;
    string temp_str = biString.str();
    char const *biChar = temp_str.c_str();
    MDNode* N = MDNode::get(C, MDString::get(C, biChar));
    BI->setMetadata("bamboo_index", N);
    bambooIndex++;
}

static long getBambooIndex(Instruction* inst) {
    MDNode *mdnode = inst->getMetadata("bamboo_index");
    if (mdnode) {
        //ConstantInt *cns_index = dyn_cast<ConstantInt>(mdnode->getOperand(0));
        //return cns_index->getSExtValue();
        string indexString = cast<MDString>(inst->getMetadata("bamboo_index")->getOperand(0))->getString().str();
        return atol(indexString.c_str());

    }
    return -1;
}

/////////////////////////////////////////////////////////////

void checkNextUseInst(Value* nextInst) {

    if( std::find(visitedInstVector.begin(), visitedInstVector.end(), nextInst) != visitedInstVector.end() ) {
        return;
    }

    // Add to visited
    visitedInstVector.push_back(nextInst);

    // Recursion to check
    Value::use_iterator UI = nextInst->use_begin();
    Value::use_iterator UE = nextInst->use_end();
    Value* nextIterateInst;
    while(UI!=UE) {
        Instruction* currentInst = dyn_cast<Instruction>(*UI);
        if( std::find(visitedInstVector.begin(), visitedInstVector.end(), currentInst) != visitedInstVector.end() ) {
            return;
        } else {
            //errs() << getLLFIIndexofInst(currentInst);
        }

        if(isa<CmpInst>(currentInst)) {
            errs() << "cmp " << getBambooIndex(currentInst) << "\n";
        } else if(isa<CallInst>(currentInst)) {
            //errs() << " - FUNC\n";

            errs() << "call " << getBambooIndex(currentInst) << " " << dyn_cast<CallInst>(currentInst)->getCalledFunction()->getName() << "\n";
        } else if(isa<StoreInst>(currentInst)) {
            errs() << "store " << getBambooIndex(currentInst) << "\n";
            if( dyn_cast<StoreInst>(currentInst)->getPointerOperand() == nextInst ) {
                // Next use is pointer in store
                //errs() << ".ST(A)->";
                //errs() << "\n";
                return;
            }
            //errs() << " - STORE\n";
        } else if(isa<ReturnInst>(currentInst)) {
            //errs() << " - RTN\n";
        } else if(isa<LoadInst>(currentInst)) {
            //errs() << ".LD->";
            //errs() << "\n";
            //return;
        } else if(isa<BinaryOperator>(currentInst)) {
            errs() << "bio " << getBambooIndex(currentInst) << "\n";
        }
        //errs() << "->";

        nextIterateInst = *UI;
        checkNextUseInst(nextIterateInst);
        UI++;
    }
}

static void modifyModule(Module* module) {

    errs() << getenv("S_INDEX") << "\n";

    // Index
    for (Module::iterator F = module->begin(), e = module->end(); F != e; F++) {
        for(Function::iterator BB = F->begin(), E = F->end(); BB != E; ++BB) {
            for(BasicBlock::iterator BI = BB->begin(), BE = BB->end(); BI != BE; ++BI) {
                // Check if the instruction has return value
                std::list<User*> inst_uses;
                bool hasReturnValue = false;
                
                for (Value::use_iterator use_it = BI->use_begin(); use_it != BI->use_end(); ++use_it) {
                    hasReturnValue = true;
                }

                // If so, we index it
                if(hasReturnValue == true && !isa<AllocaInst>(BI) ) {
                    indexInstruction(BI);
                }

                if (BI->getOpcode() == 2 || BI->getOpcode() == 29) {
                    indexInstruction(BI);
                }
            }
        }
    }

    // Profilel
    // Parse index to inject: we use 'fiInstIndex' parameter
    std::vector<std::string> fiInstIndexVector;
    if(getenv("fiInstIndex")) {
        std::string str(getenv("fiInstIndex"));
        std::string buf;
        std::stringstream ss(str);
        while(ss >> buf) {
            fiInstIndexVector.push_back(buf);
        }
    }

    long targetIndex = 0;

    targetIndex = std::atol(getenv("S_INDEX"));

    for (Module::iterator F = module->begin(), e = module->end(); F != e; F++) {
        if( F->getName().find("bambooProfile") != std::string::npos ) continue;
        //errs() << F->getName() << "\n";

        for(Function::iterator BB = F->begin(), E = F->end(); BB != E; ++BB) {
            for(BasicBlock::iterator BI = BB->begin(), BE = BB->end(); BI != BE; ++BI) {

                long llfiIndex = getBambooIndex(BI);
                int opcode = BI->getOpcode();
                
                if (llfiIndex == targetIndex) {
                    
                    checkNextUseInst(dyn_cast<Value>(BI));
                    break;
                }
            }
        }
    }
}

static bool called_compile = false;

nvvmResult nvvmAddModuleToProgram(nvvmProgram prog, const char *bitcode, size_t size, const char *name)
{
    bind_lib(LIBNVVM);
    bind_sym(libnvvm, nvvmAddModuleToProgram, nvvmResult, nvvmProgram, const char*, size_t, const char*);

    // Load module from bitcode.
    if (getenv("CICC_MODIFY_UNOPT_MODULE") && !initial_module)
    {

        string source = "";
        source.reserve(size);
        source.assign(bitcode, bitcode + size);
        MemoryBuffer *input = MemoryBuffer::getMemBuffer(source);
        string err;
        LLVMContext &context = getGlobalContext();
        initial_module = ParseBitcodeFile(input, context, &err);
        if (!initial_module)
            cerr << "Error parsing module bitcode : " << err;

        writeIrToFile(initial_module, "unopt_bamboo_before.ll");

        modifyModule(initial_module);

        // Dump unopt ir to file
        /*
           ofstream irfile;
           irfile.open("bamboo.ll");
           irfile << source;
           irfile.close();
         */
        writeIrToFile(initial_module, "unopt_bamboo_after.ll");

        // Save module back into bitcode.
        SmallVector<char, 128> output;
        raw_svector_ostream outputStream(output);
        WriteBitcodeToFile(initial_module, outputStream);
        outputStream.flush();

        // Call real nvvmAddModuleToProgram
        return nvvmAddModuleToProgram_real(prog, output.data(), output.size(), name);
    }

    called_compile = true;

    // Call real nvvmAddModuleToProgram
    return nvvmAddModuleToProgram_real(prog, bitcode, size, name);
}

#undef bind_lib

#define LIBC "libc.so.6"

static void* libc = NULL;

#define bind_lib(lib) \
	if (!libc) \
{ \
	libc = dlopen(lib, RTLD_NOW | RTLD_GLOBAL); \
	if (!libc) \
	{ \
		fprintf(stderr, "Error loading %s: %s\n", lib, dlerror()); \
		abort(); \
	} \
}

static Module* optimized_module = NULL;

struct tm *localtime(const time_t *timep)
{
    static bool localtime_first_call = true;

    bind_lib(LIBC);
    bind_sym(libc, localtime, struct tm*, const time_t*);

    if (getenv("CICC_MODIFY_OPT_MODULE") && called_compile && localtime_first_call)
    {
        localtime_first_call = false;

        writeIrToFile(optimized_module, "opt_bamboo_before.ll");

        modifyModule(optimized_module);

        writeIrToFile(optimized_module, "opt_bamboo_after.ll");

    }

    return localtime_real(timep);
}

#include <unistd.h>

#define MAX_SBRKS 16

struct sbrk_t {
    void* address;
    size_t size;
};
static sbrk_t sbrks[MAX_SBRKS];
static int nsbrks = 0;

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

extern "C" void* malloc(size_t size)
{
    if (!size) return NULL;

    static bool __thread inside_malloc = false;

    if (!inside_malloc)
    {
        inside_malloc = true;

        bind_lib(LIBC);
        bind_sym(libc, malloc, void*, size_t);

        inside_malloc = false;

        void* result = malloc_real(size);

        if (called_compile && !optimized_module)
        {
            if (size == sizeof(Module)) {
                optimized_module = (Module*)result;
            }
        }

        return result;
    }

    void* result = sbrk(size);
    if (nsbrks == MAX_SBRKS)
    {
        fprintf(stderr, "Out of sbrk tracking pool space\n");
        pthread_mutex_unlock(&mutex);
        abort();
    }
    pthread_mutex_lock(&mutex);
    sbrk_t s;
    s.address = result;
    s.size = size;
    sbrks[nsbrks++] = s;
    pthread_mutex_unlock(&mutex);

    return result;
}

extern "C" void* realloc(void* ptr, size_t size)
{
    bind_lib(LIBC);
    bind_sym(libc, realloc, void*, void*, size_t);

    for (int i = 0; i < nsbrks; i++)
        if (ptr == sbrks[i].address)
        {
            void* result = malloc(size);
#define MIN(a,b) (a) < (b) ? (a) : (b)
            memcpy(result, ptr, MIN(size, sbrks[i].size));
            return result;
        }

    return realloc_real(ptr, size);
}

extern "C" void free(void* ptr)
{
    bind_lib(LIBC);
    bind_sym(libc, free, void, void*);

    pthread_mutex_lock(&mutex);
    for (int i = 0; i < nsbrks; i++)
        if (ptr == sbrks[i].address) return;
    pthread_mutex_unlock(&mutex);

    free_real(ptr);
}



