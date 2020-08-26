import sys 

predic_file = sys.argv[1]
prediction_file = open(predic_file)

new_prediction = open("new_prediction.results", "w+")

counter = int(sys.argv[2])
for line in prediction_file:
    if "FI index" in line:
        index = line.index(",")
        line = "FI index: " + `counter` + "," + line[index+1:]
        counter+=1
        new_prediction.write(line)

prediction_file.close()
new_prediction.close()

