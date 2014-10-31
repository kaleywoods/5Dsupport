%% getScan
%
% filenames = getScan(scanFiles, scanNumber, outputDir (optional))
% 
% Given cell array scanFiles (from helical_sync_toolbox), returns
% filenames of the .dcm corresponding to specified scan number.
% If outputDir argument is provided, copies these files to
% outputDir.  

function filenames = getScan(varargin)

scanFiles = varargin{1};
scanNumber = varargin{2};

if nargin > 2
outputDir = varargin{3};
writeFiles = true;
else
writeFiles = false;
end

filenames = scanFiles(cell2mat(scanFiles(:,2)) == scanNumber,1);

if writeFiles
outputDir = fullfile(outputDir,sprintf('%d',scanNumber));
mkdir(outputDir)
copyScan=waitbar(0,sprintf('Copying scan %d...',scanNumber));

for ind = 1:length(filenames)
    cpCmd = ['cp -f ' '"' filenames{ind} '" ' '"' outputDir '"']; 
    system(cpCmd);
    waitbar((ind/length(filenames)), copyScan);
end
close(copyScan)    

end
