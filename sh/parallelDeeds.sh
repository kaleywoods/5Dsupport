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

refScan=$1/scan_$3_cut.nii
ls $1/*nii | parallel --progress -j$4 echo $refScan {} $2/{/}_registered 2.0 128.0


#ls $1/*nii | parallel echo $refScan {} 'printf -v '%s/scan_%d_registered_to_%d' $2 ''echo {/.}' | sed "s/[^-1-9]//g"' $3' 2.0 128.0 

#ls $1/*nii | parallel echo $refScan {} "sed "s/[^-0-9]//g" {}"


ls $2/*deformed.nii | parallel --progress -j$4 resizeFlow {.}

##numFiles${#scanFilenames[@]}
#
## Set reference scan filename
#
## Loop over scans
#for i in $(seq 1 $numFiles);
#do
#printf -v movingFilename '%s/scan_%d_cut.nii' $1 $i
#printf -v outputFilename '%s/scan_%d_registered_to_%d' $2 $i $3
#printf -v resizeFilename '%s/scan_%d_registered_to_%d' $2 $i $3
#
#deedsMIND $refScan $movingFilename $outputFilename 2.0 128.0
#resizeFlow $resizeFilename
#done


#echo "$movingFilename"
#echo $refScan
#echo ${scanFilenames[@]}
   
