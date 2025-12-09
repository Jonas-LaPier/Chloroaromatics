#!/bin/bash

# --- SLURM SBATCH Directives ---
# Name the job array
#SBATCH --job-name=formchk_freq

# Adjust time limit based on file size (formchk is typically fast)
#SBATCH --time=0-00:00:30

#SBATCH --cpus-per-task=1        # formchk uses 1 CPU
#SBATCH --ntasks=1               # request 1 task per job
#SBATCH --mem-per-cpu=500mb       # request 500 MB per CPU
#SBATCH --nodes=1                # request 1 node

# Specify the array range: will be calculated dynamically based on input files
# Note: You can override this by passing --array=N-M on the command line
#SBATCH --array=1-58

# Send output to a named file for each task
#SBATCH --output=slurm_out/formchk_freq.%A_%a.out
#SBATCH --error=slurm_error/formchk_freq.%A_%a.err

# --- Configuration Variables (Modify these for your workflow) ---
CHK_INPUT_DIR="frequency_chks"        # Directory containing .chk files
FCHK_OUTPUT_DIR="frequency_fchk"      # Directory for .fchk formatted checkpoint files

# Ensure output directories exist
mkdir -p slurm_out slurm_error "$FCHK_OUTPUT_DIR"

# --- Job Execution Commands ---

echo "--- Starting formchk Job Array Task ---"
echo "This is Job ID: $SLURM_JOB_ID (Array Master Job ID: $SLURM_ARRAY_JOB_ID)"
echo "This is Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Running on node: $(hostname)"
echo "Process ID (PID): $$"

# Get the list of .chk files and select the one for this task
CHK_FILES=($(ls "$CHK_INPUT_DIR"/*.chk 2>/dev/null | sort))

# Check if we have files
if [ ${#CHK_FILES[@]} -eq 0 ]; then
    echo "ERROR: No .chk files found in $CHK_INPUT_DIR"
    exit 1
fi

# Warn if array size doesn't match file count
NUM_FILES=${#CHK_FILES[@]}
if [ $SLURM_ARRAY_TASK_MAX -lt $NUM_FILES ]; then
    echo "WARNING: Array size ($SLURM_ARRAY_TASK_MAX) is less than number of files ($NUM_FILES)"
    echo "Some files will not be processed. Re-submit with:"
    echo "  sbatch --array=1-$NUM_FILES $0"
fi

# Calculate which file this task should process (1-indexed to 0-indexed)
FILE_INDEX=$((SLURM_ARRAY_TASK_ID - 1))

# Check if the file index is valid
if [ $FILE_INDEX -ge ${#CHK_FILES[@]} ]; then
    echo "ERROR: Array task $SLURM_ARRAY_TASK_ID exceeds number of input files (${#CHK_FILES[@]})"
    exit 1
fi

CHK_FILE="${CHK_FILES[$FILE_INDEX]}"
CHK_FILENAME=$(basename "$CHK_FILE" .chk)

echo "Processing: $CHK_FILE"
echo "Output file will be saved to:"
echo "  - Formatted Checkpoint: $FCHK_OUTPUT_DIR/${CHK_FILENAME}.fchk"

echo "Starting formchk conversion at $(date)..."
module load chemistry gaussian
formchk "$CHK_FILE" "$FCHK_OUTPUT_DIR/${CHK_FILENAME}.fchk"
FORMCHK_EXIT=$?
echo "formchk conversion finished at $(date) with exit code: $FORMCHK_EXIT"

if [ $FORMCHK_EXIT -eq 0 ]; then
    echo "Successfully converted: $FCHK_OUTPUT_DIR/${CHK_FILENAME}.fchk"
else
    echo "ERROR: formchk conversion failed with exit code $FORMCHK_EXIT"
    exit $FORMCHK_EXIT
fi

echo "Task completed successfully."
