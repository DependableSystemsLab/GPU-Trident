import os

f1 = open("readable_indexed.ll")


new_file = ""
next_line_indexed = False
index = -1
para_index = -1


for line in f1:
     if "call void @profileCount" not in line:
        if "!bamboo_index" in line:
            dbg_index = line.find("!dbg")
            bamboo_index = line.find("!bamboo")
            line_s = line[:dbg_index]
            line_end = line[bamboo_index:]
            line2 = line_s + line_end
            new_file += line2.replace("!bamboo_index", "!llfi_index")
        else:
            if "!dbg" in line:
                dbg_index = line.find(", !dbg")
                new_file += line[:dbg_index] + '\n'
            else:
                new_file += line
            
"""            
for line in f1:
    if "call void @profileCount" not in line:
        if next_line_indexed == True:
            next_line_indexed = False
            dbg_index = line.find("!dbg")
            new_file += line[:dbg_index] + '!llfi_index !' + str(index) + '\n' 
        else:
            para_index+=1
            if 'br' not in line:
                new_file += line
            else:
                para_index += 100
                dbg_index = line.find("!dbg")
                new_file += line[:dbg_index] + '!llfi_index !' + str(para_index) + '\n' 
            
    else:
        next_line_indexed = True
        index = int(line[len("  call void @profileCount(i64 "):-2])
        para_index = index
"""
f1.close()

f2 = open("llfi_indexed.ll", 'w')

f2.write(new_file)

f2.close()
        