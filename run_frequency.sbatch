#!/bin/bash

# --- SLURM SBATCH Directives ---
# Name the job array
# %A is the Job ID, %a is the Array Task ID
#SBATCH --job-name=gaussian_array

# Adjust time limit based on your Gaussian job complexity (e.g., 2 hours)
#SBATCH --time=0-02:00:00

#SBATCH --cpus-per-task=4        # request 4 CPUs per task (Gaussian can use multiple)
#SBATCH --ntasks=1               # request 1 task per job
#SBATCH --mem-per-cpu=2100MB        # request 2.1 GB per CPU (8.4 GB total)
#SBATCH --nodes=1                # request 1 node

# Specify the array range: will be calculated dynamically based on input files
# Note: You can override this by passing --array=N-M on the command line
#SBATCH --array=1-2

# Send output to a named file for each task
#SBATCH --output=slurm_out/gaussian.%A_%a.out
#SBATCH --error=slurm_error/gaussian.%A_%a.err

# --- Configuration Variables (Modify these for your workflow) ---
INPUT_DIR="frequency_inputs"        # Directory containing .gjf input files
CHK_OUTPUT_DIR="frequency_chks"    # Directory for .chk checkpoint files
LOG_OUTPUT_DIR="frequency_logs"    # Directory for Gaussian log files

# Ensure output directories exist
mkdir -p slurm_out slurm_error "$CHK_OUTPUT_DIR" "$LOG_OUTPUT_DIR"

# Clear any existing SLURM output/error files to avoid clutter
# (safe no-op if directories are empty)
rm -f slurm_out/* slurm_error/* 2>/dev/null || true

# --- Job Execution Commands ---

echo "--- Starting Gaussian Job Array Task ---"
echo "This is Job ID: $SLURM_JOB_ID (Array Master Job ID: $SLURM_ARRAY_JOB_ID)"
echo "This is Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Running on node: $(hostname)"
echo "Process ID (PID): $$"

# Get the list of .gjf files and select the one for this task
GJF_FILES=($(ls "$INPUT_DIR"/*.gjf 2>/dev/null | sort))

# Check if we have files
if [ ${#GJF_FILES[@]} -eq 0 ]; then
    echo "ERROR: No .gjf files found in $INPUT_DIR"
    exit 1
fi

# Warn if array size doesn't match file count
NUM_FILES=${#GJF_FILES[@]}
if [ $SLURM_ARRAY_TASK_MAX -lt $NUM_FILES ]; then
    echo "WARNING: Array size ($SLURM_ARRAY_TASK_MAX) is less than number of files ($NUM_FILES)"
    echo "Some files will not be processed. Re-submit with:"
    echo "  sbatch --array=1-$NUM_FILES $0"
fi

# Calculate which file this task should process (1-indexed to 0-indexed)
FILE_INDEX=$((SLURM_ARRAY_TASK_ID - 1))

# Check if the file index is valid
if [ $FILE_INDEX -ge ${#GJF_FILES[@]} ]; then
    echo "ERROR: Array task $SLURM_ARRAY_TASK_ID exceeds number of input files (${#GJF_FILES[@]})"
    exit 1
fi

GJF_FILE="${GJF_FILES[$FILE_INDEX]}"
GJF_FILENAME=$(basename "$GJF_FILE" .gjf)

echo "Processing: $GJF_FILE"
echo "Output files will be saved to:"
echo "  - Checkpoint: $CHK_OUTPUT_DIR/${GJF_FILENAME}.chk"
echo "  - Log: $LOG_OUTPUT_DIR/${GJF_FILENAME}.log"
echo "The working directory is: $(pwd)"

echo "Starting Gaussian 16 computation at $(date)..."
module load chemistry gaussian
g16 < "${INPUT_DIR}/${GJF_FILENAME}.gjf" > "${LOG_OUTPUT_DIR}/${GJF_FILENAME}.log"
GAUSSIAN_EXIT=$?
echo "Gaussian 16 computation finished at $(date) with exit code: $GAUSSIAN_EXIT"

echo "Log file saved to $LOG_OUTPUT_DIR/${GJF_FILENAME}.log"
echo "Task completed successfully."
