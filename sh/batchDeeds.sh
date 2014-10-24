#!/bin/bash
# batchDeeds

# Registers CT scans to reference scan "using deedsMIND algorithm.
# Dependencies: realpath

# See if user input all parameters
if [ "$#" -ne 3 ]; then
echo "Usage: batchDeeds inputDirectory outputDirectory referenceScanNumber"
exit
fi

# Make output directory
mkdir $2
# Get list of files in inputDirectory

shopt -s nullglob
declare -a scanFilenames
scanFilenames=($1/*.nii)
shopt -u nullglob

numFiles=${#scanFilenames[@]}

# Set reference scan filename

refScan=$1/scan_$3_cut.nii
# Loop over scans
for i in $(seq 1 $numFiles);
do
printf -v movingFilename '%s/scan_%d_cut.nii' $1 $i
printf -v outputFilename '%s/scan_%d_registered_to_%d' $2 $i $3
printf -v resizeFilename '%s/scan_%d_registered_to_%d' $2 $i $3

deedsMIND $refScan $movingFilename $outputFilename 2.0 128.0
resizeFlow $resizeFilename
done


#echo "$movingFilename"
#echo $refScan
#echo ${scanFilenames[@]}
   
