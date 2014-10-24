#!/bin/bash

# Make symbolic links so that all my code isnt all over the place

# Set dropbox path
dropboxPath=/home/doconnell/Dropbox/4DCT/
gitRepoPath=/home/doconnell/5Dsupport/
archivePath=/home/doconnell/Dropbox/codeArchive

# Get list of all files in the git repository
shopt -s nullglob
declare -a gitFiles
gitFiles=(/home/doconnell/5Dsupport/{m,sh}/*.{m,sh})
shopt -u nullglob

# Create backup folder if it doesn't exist already
backupDir=/home/doconnell/Dropbox/codeArchive
if [ ! -d $backupDir ]; then
# Make output directory
mkdir $backupDir
fi

# For all files that exist in the git repository, if they exist in dropbox
# AND aren't already symbolic links, move them to the archive, create a
# sym link pointing to the file in the git repo.

for i in "${gitFiles[@]}";
do

	filename=$(basename $i)
	dropboxFile=$dropboxPath/$filename
	
	if [ -f $dropboxFile ] && [ ! -L $dropboxFile ]; then

		echo $dropboxFile
		
		# Move dropbox file to archive
		mv $dropboxFile $archivePath

		
		#Create symbolic link pointing to the file in the git repo	
	
		if [ ${i: -3} == ".sh" ]; then
			linkTarget=$gitRepoPath/sh/$filename
		else
			linkTarget=$gitRepoPath/m/$filename
		fi
		
		ln -s $linkTarget $dropboxFile
	fi
done

