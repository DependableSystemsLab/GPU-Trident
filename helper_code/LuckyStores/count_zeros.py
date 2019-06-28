import os

file1 = open("results/profile_mem_val_result.txt")
val_zero = 0
count = 0

for line in file1:
	line = line.split(" ")
	val = float(line[1])
	#index = int(line[1])

	if val == 0:
		val_zero += 1

	count += 1

print "Total Count:", count
print "Total Zeros:", val_zero