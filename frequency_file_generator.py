import os
from pathlib import Path

# --- Configuration ---
GEOMETRY_COMPLETED_DIR = "geometry_inputs_completed"
FREQUENCY_OUTPUT_DIR = "frequency_inputs"
GEOMETRY_CHK_DIR = "geometry_chks"
FREQUENCY_CHK_DIR = "frequency_chks"

# Gaussian frequency input header template
FREQUENCY_HEADER = """%mem=8GB
%nprocshare=4
%oldchk={geometry_chks}/{filename}.chk
%chk={frequency_chks}/{filename}_Freq.chk
# opt freq 6-311++g(d,p) guess=read geom=allcheck m062x

{filename}

"""

def generate_frequency_files():
    """
    Iterate through geometry_inputs_completed folder, extract filenames (strip extensions),
    and generate Gaussian frequency input files (.gjf) in frequency_inputs folder.
    """
    # Ensure output directory exists
    os.makedirs(FREQUENCY_OUTPUT_DIR, exist_ok=True)
    
    # Check if input directory exists
    if not os.path.isdir(GEOMETRY_COMPLETED_DIR):
        print(f"ERROR: Directory '{GEOMETRY_COMPLETED_DIR}' not found.")
        return
    
    # Get list of files in geometry_inputs_completed
    try:
        files = os.listdir(GEOMETRY_COMPLETED_DIR)
    except OSError as e:
        print(f"ERROR: Could not read directory '{GEOMETRY_COMPLETED_DIR}': {e}")
        return
    
    if not files:
        print(f"WARNING: No files found in '{GEOMETRY_COMPLETED_DIR}'")
        return
    
    generated_count = 0
    
    # Iterate through each file
    for filename in sorted(files):
        filepath = os.path.join(GEOMETRY_COMPLETED_DIR, filename)
        
        # Skip directories
        if os.path.isdir(filepath):
            continue
        
        # Strip extension to get base filename
        base_name = os.path.splitext(filename)[0]
        
        # Create the frequency input content
        frequency_content = FREQUENCY_HEADER.format(
            geometry_chks=GEOMETRY_CHK_DIR,
            frequency_chks=FREQUENCY_CHK_DIR,
            filename=base_name
        )
        
        # Write the frequency input file
        output_filepath = os.path.join(FREQUENCY_OUTPUT_DIR, f"{base_name}_OptFreq.gjf")
        try:
            with open(output_filepath, "w") as f:
                f.write(frequency_content)
            print(f"✓ Generated: {output_filepath}")
            generated_count += 1
        except IOError as e:
            print(f"ERROR: Could not write '{output_filepath}': {e}")
    
    # Summary
    print("-" * 60)
    print(f"Successfully generated {generated_count} frequency input file(s).")
    print(f"Files saved to: {FREQUENCY_OUTPUT_DIR}/")
    print("-" * 60)

if __name__ == "__main__":
    print("Starting frequency input file generation...")
    print(f"Reading from: {GEOMETRY_COMPLETED_DIR}/")
    print(f"Writing to: {FREQUENCY_OUTPUT_DIR}/")
    print("-" * 60)
    generate_frequency_files()
