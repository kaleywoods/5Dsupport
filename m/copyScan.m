%% copyScan: Copy the dicom images of a selected scan into a seperate
% directory for importing into MIM.
%
% Arguments (in):
% scanFiles: .mat file created by scanSync containing filenames for scan dicoms
% outputDir: where to put the scan.  A subdirectory, outputDir/scanNumber is created.
% scanNumber: which scan to copy.
%

function copyScan(scanFiles, outputDir, scanNumber);

% Find indices of scan
scanInds = cellfun(@(x) x == scanNumber, scanFiles(:,2));
% Create output directory subfolder
mkdir(fullfile(outputDir,num2str(scanNumber)));
% Copy scan, collect errors
errors = cellfun(@(x) cpScan(x, fullfile(outputDir,num2str(scanNumber))), scanFiles(scanInds,1), 'uni', false);

% Check for errors
if any(cell2mat(errors))
	error('Error copying scan.');
end

function result = cpScan(source, destination)
cpCmd = ['cp -f ' '"' source '" ' '"' destination '"'];
[~,result] = system(cpCmd);
