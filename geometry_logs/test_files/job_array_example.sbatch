#!/bin/bash

# --- SLURM SBATCH Directives ---
# Name the job array
# %A is the Job ID, %a is the Array Task ID
# The full name will look like: array_sim.12345_1.out
#SBATCH --job-name=array_sim

# Set the wall clock time limit to 35 seconds
# Each array task will run for this duration
#SBATCH --time=0-00:00:35

#SBATCH --cpus-per-task=1 # request 1 CPU per task
#SBATCH --ntasks=1 # request 1 task per job
#SBATCH --mem-per-cpu=500M # request 500 MB of memory per CPU
#SBATCH --nodes=1 # request 1 node

# Specify the array range: 1 to 4 (submitting 4 jobs)
# The variable $SLURM_ARRAY_TASK_ID will range from 1 to 4
#SBATCH --array=1-4

# Send output to a named file for each task
# %A = Job ID, %a = Array Task ID
# This prevents output from one task overwriting another's
#SBATCH --output=outputs/array_output.%A_%a.out
#SBATCH --error=outputs/array_error.%A_%a.err

# Ensure outputs directory exists (do this after SBATCH directives)
mkdir -p outputs

# --- Job Execution Commands ---

# Print a friendly message to the output file
echo "--- Starting Job Array Task ---"

# Print the essential Slurm environment variables for this specific task
echo "This is Job ID: $SLURM_JOB_ID (Array Master ID: $SLURM_ARRAY_JOB_ID)"
echo "This is Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Running on node: $(hostname)"
echo "Process ID (PID): $$"

# Execute the core task: Sleep for 30 seconds (0.5 minutes)
# This simulates your actual computational work
echo "Starting 30 second computation..."
sleep 30

echo "Computation finished. Task exiting."