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
#SBATCH --output=outputs/gaussian.%A_%a.out
#SBATCH --error=outputs/gaussian.%A_%a.err

# --- Configuration Variables (Modify these for your workflow) ---
INPUT_DIR="geometry_input"        # Directory containing .gjf input files
CHK_OUTPUT_DIR="geometry_chks"    # Directory for .chk checkpoint files
LOG_OUTPUT_DIR="geometry_logs"    # Directory for Gaussian log files

# Ensure output directories exist
mkdir -p outputs "$CHK_OUTPUT_DIR" "$LOG_OUTPUT_DIR"

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

echo "Processing: $GJF_FILE"
echo "Output files will be saved to:"
echo "  - Checkpoint: $CHK_OUTPUT_DIR/${GJF_FILENAME}.chk"
echo "  - Log: $LOG_OUTPUT_DIR/${GJF_FILENAME}.log"

# Create a temporary directory for this job's scratch files
SCRATCH_DIR="/scratch/${USER}/gaussian_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$SCRATCH_DIR"

# Copy input file to scratch directory
cp "$GJF_FILE" "$SCRATCH_DIR/${GJF_FILENAME}.gjf"
cd "$SCRATCH_DIR"

# Run Gaussian 16
# Replace 'g16' with the correct command on your Sherlock cluster
echo "Starting Gaussian 16 computation at $(date)..."
g16 < "${GJF_FILENAME}.gjf" > "${GJF_FILENAME}.log"
GAUSSIAN_EXIT=$?
echo "Gaussian 16 computation finished at $(date) with exit code: $GAUSSIAN_EXIT"

# Copy output files back to the designated directories
if [ -f "${GJF_FILENAME}.chk" ]; then
    cp "${GJF_FILENAME}.chk" "$(cd - >/dev/null && pwd)/$CHK_OUTPUT_DIR/"
    echo "Checkpoint file saved to $CHK_OUTPUT_DIR/${GJF_FILENAME}.chk"
else
    echo "WARNING: Checkpoint file not found in scratch directory"
fi

if [ -f "${GJF_FILENAME}.log" ]; then
    cp "${GJF_FILENAME}.log" "$(cd - >/dev/null && pwd)/$LOG_OUTPUT_DIR/"
    echo "Log file saved to $LOG_OUTPUT_DIR/${GJF_FILENAME}.log"
else
    echo "WARNING: Log file not found in scratch directory"
fi

# Clean up scratch directory
cd - >/dev/null
rm -rf "$SCRATCH_DIR"

echo "Task completed successfully."