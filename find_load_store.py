
f = open('readable_indexed.ll')

index = 0
for line in f:
    if ("call void @profileCount(i64 " in line):
        index = str(line[len("  call void @profileCount(i64 "):-2])
    
    if ("  store " in line):
        print index + " 0.75"
    
    if ("= load " in line):
        print index + " 0.75"
