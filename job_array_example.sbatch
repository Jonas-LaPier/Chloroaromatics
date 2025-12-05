#!/bin/bash

# --- SLURM SBATCH Directives ---
# Name the job array
# %A is the Job ID, %a is the Array Task ID
# The full name will look like: array_sim.12345_1.out
#SBATCH --job-name=array_sim

# Set the wall clock time limit to 1 minute
# Each array task will run for this duration
#SBATCH --time=0-00:01:00

# Request resources for *each* individual task in the array
# We need only 1 CPU core per task
#SBATCH --cpus-per-task=1
# Request only 1 task in the allocation (Slurm will manage the array tasks)
#SBATCH --ntasks=1
# Request 500 MB of memory per task
#SBATCH --mem-per-cpu=500M

# Request only 1 node for simplicity, though the tasks may be spread out
#SBATCH --nodes=1

# Specify the array range: 1 to 4 (submitting 4 jobs)
# The variable $SLURM_ARRAY_TASK_ID will range from 1 to 4
#SBATCH --array=1-4

# Send output to a named file for each task
# %A = Job ID, %a = Array Task ID
# This prevents output from one task overwriting another's
#SBATCH --output=array_output.%A_%a.out
#SBATCH --error=array_error.%A_%a.err

# --- Job Execution Commands ---

# Print a friendly message to the output file
echo "--- Starting Job Array Task ---"

# Print the essential Slurm environment variables for this specific task
echo "This is Job ID: $SLURM_JOB_ID (Array Master ID: $SLURM_ARRAY_JOB_ID)"
echo "This is Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Running on node: $(hostname)"
echo "Process ID (PID): $$"

# Execute the core task: Sleep for 60 seconds (1 minute)
# This simulates your actual computational work
echo "Starting 60 second computation..."
sleep 60

echo "Computation finished. Task exiting."