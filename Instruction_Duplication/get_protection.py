
import os

for dirs in os.listdir(os.curdir):

	if os.path.isfile(dirs):
		continue

	count = 0
	file1 = open(dirs + "/protection_curve.csv")

	for line in file1:
		count+=1

		if count == 11:
			trident_11 = float(line)

		if count == 22:
			trident_22 = float(line)

	print(dirs + "," +str(trident_11) + "," +str(trident_22))