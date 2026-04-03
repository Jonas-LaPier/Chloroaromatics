#!/bin/bash

# Define the Python script to run
PYTHON_SCRIPT="/home/groups/mauter/akshay/watertap_private/watertap/examples/flexibility/supply_curves/supplycurve_unit.py"
# Define the name of the Conda environment you want to activate
CONDA_ENV_NAME="~/miniconda3/envs/watertap-dev3"

# Define the directory to save job files
JOB_DIR="slurm_jobs"

# Create the job directory if it doesn't exist
mkdir -p $JOB_DIR

input_file="/home/groups/mauter/akshay/watertap_private/watertap/examples/flexibility/supply_curves/scenarios.csv"

# Read the CSV file and skip the header
{
    read  # Skip the header
    while IFS=',' read -r production_target mpd vessel tariff; do
        # Create a SLURM batch script
        JOB_FILE="$JOB_DIR/job_${production_target// /_}_${mpd// /_}_${vessel// /_}_${tariff// /_}.slurm"
        cat <<EOF > "$JOB_FILE"
#!/bin/bash
#SBATCH --job-name job_${production_target// /_}_${mpd// /_}_${vessel// /_}_${tariff// /_}
#SBATCH --output $JOB_DIR/output_${production_target// /_}_${mpd// /_}_${vessel// /_}_${tariff// /_}.out
#SBATCH --error $JOB_DIR/error_${production_target// /_}_${mpd// /_}_${vessel// /_}_${tariff// /_}.err
#SBATCH --ntasks 4
#SBATCH --time 00:10:00  # Set your desired time limit
#SBATCH --mem 4GB         # Set your desired memory limit
#SBATCH --partition normal  # Set your desired partition

source ~/miniconda3/bin/activate $CONDA_ENV_NAME
export GRB_LICENSE_FILE=/home/groups/mauter/akshay/gurobi.lic

# Run the Python script with the specified arguments
python $PYTHON_SCRIPT -p "$production_target" -m "$mpd" -v "$vessel" -t "$tariff"
EOF

        # Submit the job to SLURM
        sbatch "$JOB_FILE"
    done
} < $input_file

chmod +x /home/akshay/watertap_private/watertap/examples/flexibility/supply_curves/combine_supplycurves.py
python /home/akshay/watertap_private/watertap/examples/flexibility/supply_curves/combine_supplycurves.py

echo "All Done!"