#! /usr/bin/python

import os, sys

prev_index = -1
first_line = True

os.system("rm results/simplified_inst_tuples.txt")
with open("results/inst_tuples.txt" ,'r') as itf:
    lines = itf.readlines()
    for line in lines:
        index = int(line.split(" ")[0])
        
        # If an instruction was not indexed add values for it in the tuple file
        # by setting propagation probability to 1.0
        if index != (prev_index + 1) and first_line == False:
            with open("results/simplified_inst_tuples.txt", 'a') as sf:
                while ((index - 1) != prev_index):
                    sf.write(str(prev_index + 1) + " 1.0 0.0 0.0\n")
                    prev_index += 1
                    
        pR = float( line.split(" ")[1].split(",")[0].replace("<", "") )
        mR = float( line.split(" ")[1].split(",")[1] )
        cR = float( line.split(" ")[1].split(",")[2].replace(">", "").replace("\n", "") )
        with open("results/simplified_inst_tuples.txt", 'a') as sf:
            sf.write(str(index) + " " + str(pR) + " " + str(mR) + " " + str(cR) + "\n")
            sf.close()
        prev_index = index

        first_line = False
