import os,sys
import shutil

directory = sys.argv[1]

new_prediction = os.path.join(directory, "new_prediction.results")
old_prediction = os.path.join(directory, "prediction.results")
fi_results = os.path.join(directory, "fi_breakdown.txt")

if os.path.isdir(os.path.join(directory, "output")) == False:
	os.mkdir(os.path.join(directory, "output"))

if os.path.isdir(os.path.join(directory, "output_fi")) == False:
	os.mkdir(os.path.join(directory, "output_fi"))

inst_index = "0"
with open(fi_results) as file1:
	for line in file1:
		if "-- FI Index: " in line:
			inst_index = line.split(":")[1]
			inst_index = inst_index.split(",")[0]
			break;

if inst_index == "0":
	print("Error in fault injection file")
	exit()

os.system("python modify_file.py " + old_prediction + " " + inst_index)
shutil.move("new_prediction.results", new_prediction)
os.system("python fi_getProtectionOverheadFiles.py "  + fi_results + " " + new_prediction + " " +os.path.join(directory, "output_fi"))
os.system("python getProtectionOverheadFiles.py "  + fi_results + " " + new_prediction + " " +os.path.join(directory, "output"))
os.system("python sdc_curve_fi.py " + directory + " > " + os.path.join(directory, "fi_protection_curve.csv"))
os.system("python sdc_curve.py " + directory + " > " + os.path.join(directory, "protection_curve.csv"))