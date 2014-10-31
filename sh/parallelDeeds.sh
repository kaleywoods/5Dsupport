#!/bin/bash
# parallelDeeds

# Registers CT scans to reference scan using deedsMIND algorithm.
# Excecutes numJobs registrations simulatenously 

# See if user input all parameters
if [ "$#" -ne 4 ]; then
echo "Usage: parallelDeeds inputDirectory outputDirectory referenceScanNumber numJobs"
exit
fi

if [ ! -d $2 ]; then
# Make output directory
mkdir $2
fi
# Get list of files in inputDirectory
shopt -s nullglob
declare -a scanFilenames
scanFilenames=($1/*.nii)
shopt -u nullglob

# Execute registrations
refScan=$1/scan_$3_cut.nii
ls $1/*nii | parallel --progress -j$4 deedsMIND $refScan {} $2/{/.} 2.0 128.0

# Remove the "_deformed" appended to the output image from deedsMIND and call resizeFlow
ls $2/*deformed.nii | sed 's/.\{13\}$//' | parallel --progress -j$4 resizeFlow {.}  
  
