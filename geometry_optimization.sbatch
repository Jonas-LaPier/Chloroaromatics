#!/bin/bash

# --- SLURM SBATCH Directives ---
# Name the job array
# %A is the Job ID, %a is the Array Task ID
#SBATCH --job-name=gaussian_array

# Adjust time limit based on your Gaussian job complexity (e.g., 2 hours)
#SBATCH --time=0-02:00:00

#SBATCH --cpus-per-task=4        # request 4 CPUs per task (Gaussian can use multiple)
#SBATCH --ntasks=1               # request 1 task per job
#SBATCH --mem-per-cpu=2GB        # request 2 GB per CPU (8 GB total)
#SBATCH --nodes=1                # request 1 node

# Specify the array range: adjust based on number of .gjf files
# This will be set dynamically below
#SBATCH --array=1-4

# Send output to a named file for each task
#SBATCH --output=slurm_out/gaussian.%A_%a.out
#SBATCH --error=slurm_error/gaussian.%A_%a.err

# --- Configuration Variables (Modify these for your workflow) ---
INPUT_DIR="geometry_input"        # Directory containing .gjf input files
CHK_OUTPUT_DIR="geometry_chks"    # Directory for .chk checkpoint files
LOG_OUTPUT_DIR="geometry_logs"    # Directory for Gaussian log files

# Ensure output directories exist
mkdir -p slurm_out slurm_error "$CHK_OUTPUT_DIR" "$LOG_OUTPUT_DIR"

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

# Calculate which file this task should process (1-indexed to 0-indexed)
FILE_INDEX=$((SLURM_ARRAY_TASK_ID - 1))

# Check if the file index is valid
if [ $FILE_INDEX -ge ${#GJF_FILES[@]} ]; then
    echo "ERROR: Array task $SLURM_ARRAY_TASK_ID exceeds number of input files (${#GJF_FILES[@]})"
    exit 1
fi

GJF_FILE="${GJF_FILES[$FILE_INDEX]}"
GJF_FILENAME=$(basename "$GJF_FILE" .gjf)
GJF_FILE_ABS="$(cd "$(dirname "$GJF_FILE")" && pwd)/$(basename "$GJF_FILE")"

echo "Processing: $GJF_FILE"
echo "Output files will be saved to:"
echo "  - Checkpoint: $CHK_OUTPUT_DIR/${GJF_FILENAME}.chk"
echo "  - Log: $LOG_OUTPUT_DIR/${GJF_FILENAME}.log"

echo "Starting Gaussian 16 computation at $(date)..."
module load chemistry gaussian
g16 < "$GJF_FILE_ABS" > "geometry_logs/${GJF_FILENAME}.log"
GAUSSIAN_EXIT=$?
echo "Gaussian 16 computation finished at $(date) with exit code: $GAUSSIAN_EXIT"

# Move checkpoint file to the checkpoint output directory if it was created
if [ -f "${GJF_FILENAME}.chk" ]; then
    mv "${GJF_FILENAME}.chk" "../$CHK_OUTPUT_DIR/"
    echo "Checkpoint file saved to $CHK_OUTPUT_DIR/${GJF_FILENAME}.chk"
else
    echo "WARNING: Checkpoint file not found"
fi

echo "Log file saved to $LOG_OUTPUT_DIR/${GJF_FILENAME}.log"
echo "Task completed successfully."