%% sortScans
% Create symbolic links to the dicom files used in building a 5D motion model, sorted
% into folders by scan number.
%
% Arguments:
% scanFiles - written by scanSync
% outputDir - directory to write symbolic links

function sortScans(scanFiles, outputDir)

mkdir(outputDir)
numScans = scanFiles{end,2};
for ind = 1:numScans

	% Get filenames of slices in this scan
	scanSlices = cellfun(@(x) x == ind, scanFiles(:,2));
	scanSlices = scanFiles(scanSlices,1);

	% Create symbolic links to these slices
	scanPath = fullfile(outputDir,sprintf('%d',ind));
	mkdir(scanPath);
	errors = zeros(length(scanSlices),1);
	for ind2 = 1:length(scanSlices)
		symCmd = ['ln -s ' '"' scanSlices{ind2} '" ' '"' fullfile(scanPath,sprintf('scan%d_slice%d.dcm',ind, ind2)) '"'];
		errors(ind2) = system(symCmd);
	end

	if any(errors)
	warning(sprintf('Error saving scan %d',ind));
	end
end

