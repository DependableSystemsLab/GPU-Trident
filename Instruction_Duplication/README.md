Artifact 2 - Code and data used in paper for Section VII.

# Prerequisites
1. Python 2.7.16
2. Directory with `prediction.results` (from GPU-Trident) and `fi_breakdown.txt` (contains fault injectoin results results)

# Execution
1. Run the command `python run_test.py directory`.
2. After command completion, `directory/protection_curve.csv` and `directory/fi_protection_curve.csv` contains protection provided by GPU-Trident and FI respectively at various overheads.

	Results for all the benchmarks are already present in all sub-directories.
