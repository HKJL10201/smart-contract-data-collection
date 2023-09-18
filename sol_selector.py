import os
import fnmatch

# Specify the directory where you want to search for .sol files
directory_path = 'contracts'
OUT = 'sol.log'

# Define the pattern to match .sol files
pattern = "*.sol"

# Create an empty list to store the paths of matching files
sol_file_paths = []

# Walk through the directory and its subdirectories
for root, dirs, files in os.walk(directory_path):
    for filename in fnmatch.filter(files, pattern):
        # Construct the full path to the .sol file
        sol_file_path = os.path.join(root, filename)
        # Add the path to the list
        sol_file_paths.append(sol_file_path)

# Print the list of .sol file paths
# for path in sol_file_paths:
#     print(path)

open(OUT,'w').write('\n'.join(sol_file_paths)+'\n')