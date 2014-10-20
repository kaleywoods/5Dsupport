%% getDicomHeaders
% Usage: [allScanHeaders, scanDirectoryDicoms] = getDicomHeaders(scanDirectory, waitbarMessage);
%
% Given a directory scanDirectory, returns a cell array containing headers of
% all the dicom files within, as well as a cell array containing their filenames.
%
% Optional input argument: Display a waitbar with text given by the string 
% waitMessage.

function [allScanHeaders, scanDirectoryDicoms] = getDicomHeaders(varargin)

scanDirectory = varargin{1};

if (nargin > 1)
dispWaitbar = true;
waitMessage = varargin{2};
else
dispWaitbar = false;
end

% Get list of subfolders within scan directory. Remove '.' and '..' from list
scanFoldersDir = dir(scanDirectory);
scanFoldersDir(logical(cell2mat(cellfun(@(x) ismember(x,{'.','..'}), {scanFoldersDir.name}, 'UniformOutput', false)))) = [];
scanSubfolders = {scanFoldersDir([scanFoldersDir.isdir]).name};

% Check scanDirectory for .dcm files and, if present, load their headers.
scanDirectoryFiles = {scanFoldersDir(~[scanFoldersDir.isdir]).name};
allScanHeaders = [];	

if (~isempty(scanDirectoryFiles))
	scanDirectoryDicoms = false(length(scanDirectoryFiles),1);
	if dispWaitbar
	scanDirHeaderBar = waitbar(0,waitMessage);
	end

	for ind = 1:length(scanDirectoryFiles)
	header = [];	
		try
		header = {dicominfo(fullfile(scanDirectory,scanDirectoryFiles{ind}))};
		end
	
		if ~(isempty(header))
		scanDirectoryDicoms(ind) = 1;
		allScanHeaders = cat(1,allScanHeaders,header);
		end	
		
		if dispWaitbar		
		waitbar((ind/length(scanDirectoryFiles)),scanDirHeaderBar);
		end
	end

	if dispWaitbar
	close(scanDirHeaderBar);
end

else
	scanDirectoryDicoms = 0;
end
if any(scanDirectoryDicoms)
scanDirectoryDicoms = cellfun(@(x) fullfile(scanDirectory,x), scanDirectoryFiles(scanDirectoryDicoms),'UniformOutput',false);
scanDirectoryDicoms = scanDirectoryDicoms';
else
scanDirectoryDicoms = [];
end
