import itertools
import os

# --- Configuration for Gaussian Header ---
GAUSSIAN_HEADER = """%mem=8GB
%nprocshare=4
%chk=geometry_chks/{filename}.chk
# opt am1

{title}

{charge} {multiplicity}
"""

# --- Base Coordinates from Hexachlorobenzene Template ---
# The six Carbon atoms of the ring are fixed for all isomers.
C_ATOMS = [
    'C  -3.20928   0.19943  0.00000',
    'C  -2.01150   0.93555  0.00000',
    'C  -0.77511   0.26630  0.00000',
    'C  -0.73650  -1.13907  0.00000',
    'C  -1.93429  -1.87519  0.00000',
    'C  -3.17067  -1.20594  0.00000'
]

# The six substitution sites (same coordinates for Cl/H in the starting geometry).
# The atom type (Cl or H) will be assigned based on the isomer.
# We are assuming these coordinates correspond to positions 1 through 6, in order.
SUBSTITUENT_COORDS = [
    '-4.67483  -2.13035  0.00000', # Site 1
    '-4.76193   1.03987 -0.00000', # Site 2
    ' 0.81614  -1.97951  0.00000', # Site 3
    '-1.88580  -3.64003  0.00000', # Site 4
    '-2.05998   2.70040 -0.00000', # Site 5
    ' 0.72905   1.19071  0.00000', # Site 6
]

# --- 12 Unique Chlorobenzene Isomers (Cl positions are 1-based indices) ---
# This list covers x=1 to x=6 chlorines, respecting rotational symmetry.
CHLORINE_POSITIONS = [
    (1,),                                     # Monobromo (1)
    (1, 2), (1, 3), (1, 4),                   # Dichloro (1,2 / 1,3 / 1,4)
    (1, 2, 3), (1, 2, 4), (1, 3, 5),          # Trichloro (1,2,3 / 1,2,4 / 1,3,5)
    (1, 2, 3, 4), (1, 2, 3, 5), (1, 2, 4, 5), # Tetrachloro (Symmetry: same as 1,4 / 1,3 / 1,2 dichloro)
    (1, 2, 3, 4, 5),                          # Pentachloro (Symmetry: same as 1-chloro)
    (1, 2, 3, 4, 5, 6),                       # Hexachloro
]

def generate_gjf_files(position_list):
    """
    Generates a Gaussian GJF file for a specific chlorobenzene isomer.

    Args:
        position_list (tuple): A tuple of 1-based indices where Chlorine atoms are located.
    """
    # Create the filename and title based on the chlorine positions (e.g., '135ClBz')
    position_string = "".join(map(str, position_list))
    filename_base = f"{position_string}ClBz"
    title = f"{len(position_list)}-Chloro-Benzene ({position_string})"

    # Set charge and spin multiplicity
    charge = "0"
    multiplicity = "1"
    
    # 1. Start with the fixed Carbon atoms
    all_atoms = list(C_ATOMS)
    
    # 2. Determine the atom type for each of the 6 substituent sites
    for i in range(6):
        # The position index is 1-based, Python index is 0-based (i)
        is_chlorine = (i + 1) in position_list
        
        # Get the coordinates for this site
        coords = SUBSTITUENT_COORDS[i]
        
        if is_chlorine:
            # If the position is in the list, it's Chlorine
            all_atoms.append(f"Cl {coords}")
        else:
            # If the position is NOT in the list, it's Hydrogen
            # Note: We use the same coordinates as the Cl position, which is standard
            # for generating an initial geometry with Gaussian's 'opt' keyword.
            all_atoms.append(f"H  {coords}")

    # 3. Assemble the file content
    gjf_content = GAUSSIAN_HEADER.format(filename=filename_base, title=title, charge=charge, multiplicity=multiplicity)
    gjf_content += "\n".join(all_atoms)
    gjf_content += "\n\n" # Final newlines required by GJF format

    # --- WRITE FILE TO OUTPUT DIRECTORY ---
    # Default output directory can be overridden with the
    # environment variable `GJF_OUTPUT_DIR` or changed here.
    OUTPUT_DIR = os.environ.get("GJF_OUTPUT_DIR", "geometry_input")
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    filepath = os.path.join(OUTPUT_DIR, f"{filename_base}.gjf")
    with open(filepath, "w") as f:
        f.write(gjf_content)

    print(f"--- Wrote GJF file: {filepath} ---")
    # -----------------------------

    return filepath, gjf_content


def generate_anion_intermediates(position_list):
    """
    Generate GJF files for every way of removing one chlorine from the
    provided `position_list`. Each produced species is an anion intermediate
    (charge = -1, multiplicity = 0).

    Filenames follow the pattern where the retained chlorines are shown as
    digits and the removed chlorine is represented by an underscore. Example:
    original (1,2,3,4,5) removing 3 -> '12_45_ClBzAnionIntermediate.gjf'.

    Returns a list of (filepath, content) tuples for files written.
    """
    results = []

    OUTPUT_DIR = os.environ.get("GJF_OUTPUT_DIR", "geometry_input")
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Ensure input positions is a tuple/list of ints
    original_positions = tuple(position_list)

    for removed in original_positions:
        # Build the compact pattern showing retained digits and underscore
        pattern_parts = []
        for i in range(1, 7):
            if i in original_positions:
                if i == removed:
                    pattern_parts.append("_")
                else:
                    pattern_parts.append(str(i))
        pattern = "".join(pattern_parts)
        filename_base = f"{pattern}ClBzAnionIntermediate"
        title = f"Anion Intermediate (removed {removed}) {pattern}"

        # New positions: remove the selected chlorine
        new_positions = tuple(p for p in original_positions if p != removed)

        # Anion radical electronic state
        charge = "-1"
        multiplicity = "0"

        # Assemble atoms
        all_atoms = list(C_ATOMS)
        for i in range(6):
            is_chlorine = (i + 1) in new_positions
            coords = SUBSTITUENT_COORDS[i]
            if is_chlorine:
                all_atoms.append(f"Cl {coords}")
            elif i == removed - 1:
                # The coodinate is skipped (no atom) for the removed chlorine
                continue
            else:
                all_atoms.append(f"H  {coords}")

        gjf_content = GAUSSIAN_HEADER.format(filename=filename_base, title=title, charge=charge, multiplicity=multiplicity)
        gjf_content += "\n".join(all_atoms)
        gjf_content += "\n\n"

        filepath = os.path.join(OUTPUT_DIR, f"{filename_base}.gjf")
        with open(filepath, "w") as f:
            f.write(gjf_content)

        print(f"--- Wrote Anion Radical GJF: {filepath} ---")
        results.append((filepath, gjf_content))

    return filepath

def generate_neutral_radicals_intermediates(position_list):
    """
    Generate GJF files for every way of removing one chlorine from the
    provided `position_list`. Each produced species is a neutral radical
    (charge = 0, multiplicity = 2).

    Filenames follow the pattern where the retained chlorines are shown as
    digits and the removed chlorine is represented by an underscore. Example:
    original (1,2,3,4,5) removing 3 -> '12_45_ClBzNeutralRadical.gjf'.

    Returns a list of (filepath, content) tuples for files written.
    """
    results = []

    OUTPUT_DIR = os.environ.get("GJF_OUTPUT_DIR", "geometry_input")
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Ensure input positions is a tuple/list of ints
    original_positions = tuple(position_list)

    for removed in original_positions:
        # Build the compact pattern showing retained digits and underscore
        pattern_parts = []
        for i in range(1, 7):
            if i in original_positions:
                if i == removed:
                    pattern_parts.append("_")
                else:
                    pattern_parts.append(str(i))
        pattern = "".join(pattern_parts)
        filename_base = f"{pattern}ClBzNeutralRadical"
        title = f"Neutral Radical (removed {removed}) {pattern}"

        # New positions: remove the selected chlorine
        new_positions = tuple(p for p in original_positions if p != removed)

        # Neutral radical electronic state
        charge = "0"
        multiplicity = "2"

        # Assemble atoms
        all_atoms = list(C_ATOMS)
        for i in range(6):
            is_chlorine = (i + 1) in new_positions
            coords = SUBSTITUENT_COORDS[i]
            if is_chlorine:
                all_atoms.append(f"Cl {coords}")
            elif i == removed - 1:
                # The coodinate is skipped (no atom) for the removed chlorine
                continue
            else:
                all_atoms.append(f"H  {coords}")

        gjf_content = GAUSSIAN_HEADER.format(filename=filename_base, title=title, charge=charge, multiplicity=multiplicity)
        gjf_content += "\n".join(all_atoms)
        gjf_content += "\n\n"

        filepath = os.path.join(OUTPUT_DIR, f"{filename_base}.gjf")
        with open(filepath, "w") as f:
            f.write(gjf_content)

        print(f"--- Wrote Neutral Radical GJF: {filepath} ---")
        results.append((filepath, gjf_content))

    return filepath

if __name__ == "__main__":
    print("Starting GJF file generation for all 12 unique chlorobenzene isomers...")
    
    generated_files = []
    
    # Generate initial chlorobenzene isomers
    for positions in CHLORINE_POSITIONS:
        filepath, _ = generate_gjf_files(positions)
        generated_files.append(filepath)

    print("-" * 50)
    print(f"Successfully simulated the creation of {len(generated_files)} GJF files.")
    print("File names generated (e.g., for use in a SLURM Job Array):")
    for f in generated_files:
        print(f"- {f}")
    print("-" * 50)

    # Generate anion intermediates
    for positions in CHLORINE_POSITIONS:
        filepath = generate_anion_intermediates(positions)
        generated_files.append(filepath)

    print("-" * 50)
    print(f"Successfully simulated the creation of {len(generated_files)} GJF files.")
    print("File names generated (e.g., for use in a SLURM Job Array):")
    for f in generated_files:
        print(f"- {f}")
    print("-" * 50)

    # Generate neutral radical intermediates
    for positions in CHLORINE_POSITIONS:
        filepath = generate_neutral_radicals_intermediates(positions)
        generated_files.append(filepath)

    print("-" * 50)
    print(f"Successfully simulated the creation of {len(generated_files)} GJF files.")
    print("File names generated (e.g., for use in a SLURM Job Array):")
    for f in generated_files:
        print(f"- {f}")
    print("-" * 50)
