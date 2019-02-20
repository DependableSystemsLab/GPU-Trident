
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
#include <queue>

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

struct GraphNode{
	BasicBlock* curBb;
	float prob;
	float initNodeRProb;
};

struct StoreTuple{
	float prob; // Prob. of path to reach the store
	float rProb; // Prob. of the reverse branch of the target CMP
	GraphNode* node;
};

std::map<long, StoreTuple*> storeTupleMap; // storeIndex -> storeTuple
std::map<long, float> cmpFalseProbMap;
long targetCmpIndex;
long targetHeaderBrIndex;
std::vector<long> ltcmpInst;
std::vector<long> headerBrIndexVec;
std::map<long, long> exitToHeaderMap;

static Module* initial_module = NULL;

void readBranchProb();
void readLTCmps();
std::vector<long> getStoresInBb(BasicBlock* curBb);
float getBrProb(BasicBlock* curBb, int tOrF);
long getTmnIndexOfBb(BasicBlock* bb);
long getCmpIndexOfBb(BasicBlock* curBb);
void updateAllStoresInNode(GraphNode* theNode);
void processCmp(Instruction* targetHeaderBrInst, Function* f);

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

static void modifyModule(Module* module) {

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

    readLTCmps();
    readBranchProb();
    long targetCmpIndex = std::atol(getenv("S_INDEX"));
    targetHeaderBrIndex = exitToHeaderMap[targetCmpIndex];

    for (Module::iterator F = module->begin(), e = module->end(); F != e; F++) {
        if( F->getName().find("bambooProfile") != std::string::npos ) continue;

        for(Function::iterator BB = F->begin(), E = F->end(); BB != E; ++BB) {
            for(BasicBlock::iterator BI = BB->begin(), BE = BB->end(); BI != BE; ++BI) {

                long llfiIndex = getBambooIndex(BI);
                int opcode = BI->getOpcode();
                
                if (llfiIndex == targetHeaderBrIndex) {
                    processCmp(BI, F);
                }
            }
        }
    }
}

void processCmp(Instruction* targetHeaderBrInst, Function* f) {

    // Start from header bb
    BasicBlock *initBb = targetHeaderBrInst->getParent(); // This is the header bb of the loop.
    TerminatorInst* tmnInst = initBb->getTerminator();
    long headerBrIndex = getBambooIndex(targetHeaderBrInst);
    long headerCmpIndex = getCmpIndexOfBb(initBb);
    float tmnValue = 1;

    // BFS
    std::queue<GraphNode*> gQueue;
    //////////////////////////////////
    GraphNode* initNode = new GraphNode;
    initNode -> prob = 0;
    initNode -> initNodeRProb = 0;
    initNode -> curBb = initBb;
    gQueue.push(initNode);
    //////////////////////////////////
    std::vector<GraphNode*> visitedVector;
    std::vector<GraphNode*> directDomBbsOfTarget;


    // The loop only contains 1 bb
    if(headerCmpIndex == targetCmpIndex) {
        outs() << "SDC 1\n";
        return;
    }


    while( !gQueue.empty() ) {
        GraphNode* curNode = gQueue.front();
        gQueue.pop();
        BasicBlock* curBb = curNode->curBb;

        // DEBUG
        //errs() << " \nVisiting " << getCmpIndexOfBb(curBb);
        //printf(", curprob: %.6f, initNodeRProb: %.6f\n", curNode->prob, curNode->initNodeRProb);

        // Encounter a new header bb of a loop
        long curBbBrIndex = getTmnIndexOfBb(curBb);
        if(std::find(headerBrIndexVec.begin(), headerBrIndexVec.end(), curBbBrIndex)!=headerBrIndexVec.end()) {
            if( headerBrIndex != curBbBrIndex) {
                errs() << "Loop nested found ... \n";
                return;
            }
        }

        // If this is the exit bb
        // Return cond.
        if(getCmpIndexOfBb(curNode->curBb) == targetCmpIndex && curNode->prob >= tmnValue) {
            //if(curNode->prob >= tmnValue){
            // This is the re-convergence point BB.

            // DEBUG
            //printf("... Exit, with tmnValue: %.6f, curNode.prob: %.6f \n", tmnValue, curNode->prob);
            //errs() << "\n\nStore found: " << storeTupleMap.size() << "\n";

            for (std::map<long, StoreTuple*>::iterator it = storeTupleMap.begin(); it != storeTupleMap.end(); ++it) {
                //errs() << "\n -> StoreIndex: " << it->first;
                //printf(" => prob: %.6f, rprob: %.6f\n", it->second->prob, it->second->rProb);

                long storeIndex = it->first;
                // If the target cmp bb dominates the bb containing the store, then prob is 1.
                GraphNode* storeNode = it->second->node;
                /*
                int k=0;
                int domFlag = 0;
                for(k=0;k<directDomBbsOfTarget.size();k++){
                	if( directDomBbsOfTarget.at(k) == storeNode ){
                		domFlag = 1;
                		break;
                	}
                }
                if(domFlag == 0){
                	float affProb = it->second->prob * ( 1 + it->second->rProb );
                	printf("%ld %.6f\n", storeIndex, affProb);
                }else{
                	printf("%ld 1\n", storeIndex);
                }
                */
                float fProb = cmpFalseProbMap[targetCmpIndex];
                float tProb = 1-fProb;
                float biggerProb = 1;
                if(fProb >= tProb) biggerProb = fProb;
                else biggerProb = tProb;
                float affProb = biggerProb - (1 - it->second->prob);
                printf("%ld %.6f\n", storeIndex, affProb);
            }
            return;
        }

        // Update store tuple in current node
        updateAllStoresInNode(curNode);

        TerminatorInst* curTmnInst = curBb->getTerminator();

        // Get children
        if(curTmnInst->getOpcode() == 2) {
            int ti = curTmnInst->getNumSuccessors();
            int i = 0;
            for(i=0; i<ti; i++) {
                BasicBlock* nextBb = curTmnInst->getSuccessor(i);

                /////////////////////////////////////
                GraphNode* nextNode = new GraphNode;
                nextNode -> prob = 0;
                nextNode -> initNodeRProb = 0;
                
                int j=0;
                int visitedFlag = 0;
                for(j=0; j<visitedVector.size(); j++) {
                    //if(visitedVector.at(j).curBb == nextBb && visitedVector.at(j).curBb != NULL){
                    if(visitedVector.at(j)->curBb == nextBb) {
                        nextNode = visitedVector.at(j);
                        visitedFlag = 1;
                        break;
                    }
                }
                if(visitedFlag == 0) {
                    nextNode->curBb = nextBb;
                }
                /////////////////////////////////////

                if(curBb != nextBb && nextBb != initBb) {
                    long cmpIndex = getCmpIndexOfBb(curBb);
                    if(std::find(ltcmpInst.begin(), ltcmpInst.end(), cmpIndex)==ltcmpInst.end()) {
                        // Not found in LT list
                        float brProb = 1;
                        if(ti > 1) {
                            if(i==0) {
                                // True br, i=0, tOrF=0
                                brProb = getBrProb(curBb, 0);
                            } else {
                                // False br, i=1, tOrF=1
                                brProb = getBrProb(curBb, 1);
                            }

                            // If init node, set r prob
                            if(curNode == initNode) {
                                nextNode->initNodeRProb = 1-brProb;
                                //errs() << ">>> Setting init node rprob.\n";
                                directDomBbsOfTarget.push_back(nextNode);
                            } else {
                                // If not, inhretant from parent
                                nextNode->initNodeRProb = curNode->initNodeRProb;
                            }
                        }

                        // Update path prob of next node
                        if(curNode->prob == 0) {
                            nextNode->prob = brProb;
                            //printf(" >>> new node prob: %.6f\n", brProb);
                        } else {
                            //printf(" >>> before agg. curNode.prob: %.6f, nextNode.prob: %.6f, brProb: %.6f\n", curNode->prob, nextNode->prob, brProb);
                            nextNode->prob = nextNode->prob + curNode->prob * brProb;
                            //printf(" >>> after agg. curNode.prob: %.6f, nextNode.prob: %.6f, brProb: %.6f\n", curNode->prob, nextNode->prob, brProb);
                        }

                        gQueue.push(nextNode);
                    }

                }
            }
        } else {
            tmnValue = tmnValue - curNode->prob;
        }

        int k = 0;
        int visitedFlag = 0;
        for(k=0; k<visitedVector.size(); k++) {
            if(visitedVector.at(k) == curNode) {
                visitedFlag = 1;
                break;
            }
        }
        if(visitedFlag == 0) {
            visitedVector.push_back(curNode);
        }
        //errs() << "--VistedVector size: " << visitedVector.size() << "\n";

    }

}

void updateAllStoresInNode(GraphNode* theNode) {
    BasicBlock* theBb = theNode->curBb;
    for(BasicBlock::iterator BI = theBb->begin(), BE = theBb->end(); BI != BE; ++BI) {
        if(isa<StoreInst>(BI)) {
            StoreTuple* sT = new StoreTuple;
            sT->prob = theNode->prob;
            sT->rProb = theNode->initNodeRProb;
            sT->node = theNode;
            long storeIndex = getBambooIndex(BI);
            storeTupleMap[storeIndex] = sT;
            //errs() << ">>> Store found " << storeIndex << "\n";
        }
    }
}

long getCmpIndexOfBb(BasicBlock* curBb) {
    TerminatorInst* curTmnInst = curBb->getTerminator();
    if(curTmnInst->getNumOperands() > 0) {
        if(isa<CmpInst>(curTmnInst->getOperand(0))) {
            Instruction* I = dyn_cast<Instruction>(curTmnInst->getOperand(0));
            if(I->getOpcode() == 46 || I->getOpcode() == 47) {
                return getBambooIndex(I);
            }
        }
    }
    return 0;
}

long getTmnIndexOfBb(BasicBlock* bb) {
    TerminatorInst* tmnInst = bb->getTerminator();
    return getBambooIndex(dyn_cast<Instruction>(tmnInst));
}

float getBrProb(BasicBlock* curBb, int tOrF) {
    long cmpIndex = getCmpIndexOfBb(curBb);
    //if(cmpIndex == 0) return 1;
    if(tOrF==0) {
        // True br
        return (1-cmpFalseProbMap[cmpIndex]);
    } else {
        // False br
        return cmpFalseProbMap[cmpIndex];
    }
}

std::vector<long> getStoresInBb(BasicBlock* curBb) {
    std::vector<long> storeVec;
    for(BasicBlock::iterator BI = curBb->begin(), BE = curBb->end(); BI != BE; ++BI) {
        if(isa<StoreInst>(BI)) {
            storeVec.push_back(getBambooIndex(BI));
        }
    }
    return storeVec;
}

void readLTCmps() {
    
    std::ifstream select_ltcmp_file;
    select_ltcmp_file.open(getenv("LTCMP_FILE"));
    if(!select_ltcmp_file.is_open()) {
        errs()<<"\nERROR: can not open loop_terminating_cmp_list.txt file!\n";
        exit(1);
    }

    while(select_ltcmp_file.good()) {
        std::string line;
        getline(select_ltcmp_file, line);
        if(line.empty())        continue;
        else {

            std::string input = line.c_str();
            std::istringstream ss(input);
            std::string token;

            std::vector<long long> eleVector;
            while(std::getline(ss, token, ' ')) {
                long num = 0;
                std::stringstream convert(token);
                convert >> num;
                eleVector.push_back(num);
            }
            long headerBrIndex = eleVector.at(0);
            long exitBbCmpIndex = eleVector.at(1);

            ltcmpInst.push_back(exitBbCmpIndex);
            headerBrIndexVec.push_back(headerBrIndex);
            exitToHeaderMap[exitBbCmpIndex] = headerBrIndex;
        }
    }
}

void readBranchProb() {
    std::ifstream select_cmp_prob_file;
    select_cmp_prob_file.open(getenv("CMP_PROB_FLIE"));
    if(!select_cmp_prob_file.is_open()) {
        errs()<<"\nERROR: can not open profile_cmp_prob_result.txt file!\n";
        exit(1);
    }

    while(select_cmp_prob_file.good()) {
        std::string line;
        getline(select_cmp_prob_file, line);
        if(line.empty())        continue;
        else {
            std::string input = line.c_str();
            std::istringstream ss(input);
            std::string token;

            std::vector<long long> eleVector;
            while(std::getline(ss, token, ' ')) {
                long long num = 0;
                std::stringstream convert(token);
                convert >> num;
                eleVector.push_back(num);
            }
            long cmpIndex = (long)eleVector.at(0);
            long long cmpFalseCount = eleVector.at(1);
            long long cmpTrueCount = eleVector.at(2);
            long long totalCount = cmpTrueCount + cmpFalseCount;
            float cmpFalseProb = (float)cmpFalseCount / (float)totalCount;
            float cmpTrueProb = (float)cmpTrueCount / (float)totalCount;
            if(cmpFalseProb == 0) {
                cmpFalseProb = 0.00001;
                cmpTrueProb = 1- cmpFalseProb;
            }
            if(cmpTrueProb == 0) {
                cmpTrueProb = 0.00001;
                cmpFalseProb = 1 - cmpTrueProb;
            }
            cmpFalseProbMap[cmpIndex] = cmpFalseProb;

            //printf("%.15f\n", cmpFalseProb);
            //errs() << "Select Index: " << cmpIndex << "\n";
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



