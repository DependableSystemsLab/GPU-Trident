
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

struct InstTuple {
    float pR;
    float mR;
    float cR;
};

struct InstNode {
    Instruction* nodeInst;
    float accumPR;
    float accumMR;
    float accumCR;
};

		// record crash rate
float avCR = 0;
float totalCR = 0;
long cRCount = 0;
		
std::map<long, InstTuple*> instTupleMap;
std::map<long, long long> instCountMap;

std::vector<Value*> visitedInstVector;

static Module* initial_module = NULL;

void readSTuples();

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

void checkNextUseInst(InstNode* curNode) {
    Instruction* curInst = curNode->nodeInst;
    Value* curValue = dyn_cast<Value>(curInst);
    
    if( std::find(visitedInstVector.begin(), visitedInstVector.end(), curValue) != visitedInstVector.end() ) {
        return;
    }
    
    // Process current node
    //////////////////////////////////////////////////////////////////////////////////
    // DEBUG
    //errs() << curInst->getOpcode() << " " << getLLFIIndexofInst(curInst) << " ";
    //if(isa<CallInst>(curInst)){
    //	errs() << dyn_cast<CallInst>(curInst)->getCalledFunction()->getName();
    //}
    //printf(" --> curAccum: %.6f, %.6f, %.6f\n", curNode->accumPR, curNode->accumMR, curNode->accumCR);
    //////////////////////////////////////////////////////////////////////////////////



    // If it is a terminator, add to global accum
    long curInstIndex = getBambooIndex(curInst);
    long curInstOpcode = curInst->getOpcode();
    //printf("OC:%ld\n", curInstOpcode);
    //printf("InstI:%ld\n", curInstIndex);
    if( (curInstOpcode == 2 && dyn_cast<BranchInst>(curInst)->isConditional()) || curInstOpcode == 29 /*|| curInstOpcode == 49*/ ) {
        // Result
        if(isa<StoreInst>(curInst)) {
            printf("%ld store: %.6f, %.6f, %.6f\n", curInstIndex, curNode->accumPR, curNode->accumMR, curNode->accumCR);
        } else if(isa<CallInst>(curInst) && dyn_cast<Value>(curInst)->getNumUses() == 0 ) {
            printf("%ld call %s: %.6f, %.6f, %.6f\n", curInstIndex, dyn_cast<CallInst>(curInst)->getCalledFunction()->getName(), curNode->accumPR, curNode->accumMR, curNode->accumCR);
        } else if(isa<BranchInst>(curInst) && dyn_cast<BranchInst>(curInst)->isConditional() ) {
            long cmpIndex = getBambooIndex( dyn_cast<Instruction>(curInst->getOperand(0)) );
            printf("%ld cmp: %.6f, %.6f, %.6f\n", cmpIndex, curNode->accumPR, curNode->accumMR, curNode->accumCR);
        }
        //printf("What now\n");
        return;
    }
    
    
    // Add to visited
    visitedInstVector.push_back(curValue);
    
    // Recursion to check
    Value::use_iterator UI = curValue->use_begin();
    Value::use_iterator UE = curValue->use_end();
    Value* nextIterateInst;
    std::stack<InstNode*> childStack;
    
    while(UI!=UE) {
    
        Instruction* childInst = dyn_cast<Instruction>(*UI);

        if( std::find(visitedInstVector.begin(), visitedInstVector.end(), childInst) == visitedInstVector.end() ) {
            
            //printf("Inside\n");
            nextIterateInst = *UI;
            InstNode* nextNode = new InstNode;
            nextNode->accumPR = 0;
            nextNode->accumCR = 0;
            nextNode->accumMR = 0;
            nextNode->nodeInst = childInst;

            long nextInstIndex = getBambooIndex(childInst);
            
            float nextCR = instTupleMap[nextInstIndex]->cR;
            
            float nextPR = instTupleMap[nextInstIndex]->pR;
            float nextMR = instTupleMap[nextInstIndex]->mR;

            // Check if the next inst is a store
            if(isa<StoreInst>(childInst)) {
                if( dyn_cast<StoreInst>(childInst)->getPointerOperand() == curInst ) {
                    // Cur inst is used as pointer in the next store inst
                    nextCR = avCR;
                    nextPR = 1 - avCR;
                    nextMR = 0;
                    //errs() << "Used in store as adrs\n";
                } else {
                    // This is because STORE has 2 types of tuples depending on its input position.
                    nextCR = 0;
                    nextPR = 1;
                    nextMR = 0;
                }
            }

            //printf(" -- nextCR: %.f, nextPR: %.f, nextMR: %.f \n", nextCR, nextPR, nextMR);

            // Save to next node with accum info
            // Update accum propagation
            nextNode->accumPR = nextPR * curNode->accumPR;
            nextNode->accumCR = curNode->accumPR * nextCR + curNode->accumCR;

            // Update accum masking
            nextNode->accumMR = 1 - nextNode->accumPR - nextNode->accumCR;
            childStack.push(nextNode);
        }
        UI++;
    }

    while(!childStack.empty()) {
        checkNextUseInst( childStack.top() );
        childStack.pop();
    }
}

static void modifyModule(Module* module) {

    //errs() << getenv("STUPLE_FILE") << "\n";
    //errs() << getenv("S_INDEX") << "\n";
    
    readSTuples();

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
                    //printf("Inside\n");
                    // The target one
                    InstNode* initNode = new InstNode;
                    initNode->nodeInst = BI;
                    initNode->accumPR = 1;
                    initNode->accumMR = 0;
                    initNode->accumCR = 0;
                    checkNextUseInst( initNode );
                    break;
                }
            }
        }
    }
}

void readSTuples() {
    std::ifstream select_stuples_file;
    select_stuples_file.open(getenv("STUPLE_FILE"));
    if(!select_stuples_file.is_open()) {
        errs()<<"\nERROR: can not open tuple file!\n";
        exit(1);
    }

    while(select_stuples_file.good()) {
        std::string line;
        getline(select_stuples_file, line);
        if(line.empty())        continue;
        else {
            std::string input = line.c_str();
            std::istringstream ss(input);
            std::string token;

            std::vector<float> eleVector;
            while(std::getline(ss, token, ' ')) {
                float num = 0;
                std::stringstream convert(token);
                convert >> num;
                eleVector.push_back(num);
            }
            long index = (long)eleVector.at(0);
            float pR = eleVector.at(1);
            float mR = eleVector.at(2);
            float cR = eleVector.at(3);
            InstTuple* it = new InstTuple;
            it->pR = pR;
            it->mR = mR;
            it->cR = cR;
            instTupleMap[index] = it;
            //printf("%ld %.6f %.6f %.6f\n", index, pR, mR, cR);

            if(cR > 0) {
                totalCR += cR;
                cRCount++;
                avCR = totalCR / cRCount;
                //printf("%.6f %.6f\n", totalCR, avCR);
            }
        }
    }
    
    map<long, InstTuple*>::iterator itr; 
    
    //for (itr = instTupleMap.begin(); itr != instTupleMap.end(); ++itr) { 
        //cout << '\t' << itr->first << '\n'; 
    //} 
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



