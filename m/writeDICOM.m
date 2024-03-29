%% writeDICOM
%
% writeDICOM(patient, phaseNames)
%
% Writes 4DCT to dicom format for import into MIM.
% Uses dicom headers from the reference image
% 
%
% Dependencies: sort_nat
function writeDICOM(varargin)

% Check input
patient = varargin{1};
if nargin < 2
% Phases for current clinical protocol
phaseNames = {'0% EX' '25% EX' '50% EX' '75% EX' '100% EX' '75% IN' '50% IN' '25% IN'};
else
phaseNames = varargin{2};
end

%% Create output directory for dicom 5DCT
mkdir(fullfile(patient.model_folder,'5DCT DICOM'));

%% Load dicom headers from first scans
originalScanFolders = dir(patient.folder_original_dicoms);
originalScanFolders = originalScanFolders([originalScanFolders.isdir]);
originalScanFolders = sort_nat(cellfun(@num2str, setdiff({originalScanFolders.name},{'.','..'}),'uni',false));

refScanSlices = dir(fullfile(patient.folder_original_dicoms, originalScanFolders{patient.ref},'*')); 
refScanSlices = setdiff({refScanSlices.name},{'.','..'});
refScanHeaders = cellfun(@(x) dicominfo(fullfile(patient.folder_original_dicoms, originalScanFolders{patient.ref},x)), refScanSlices, 'uni', false);

%% Sort headers by acquisition time

acquisitionTimes = cellfun(@(x) time2sec(str2num(x.('AcquisitionTime'))), refScanHeaders, 'uni', 0);
refScanHeaders = [refScanHeaders(:) acquisitionTimes(:)];
refScanHeaders = sortrows(refScanHeaders, 2);
refScanHeaders = refScanHeaders(:,1);

%% Convert 5DCT phase images to dicom and save
saveBar = waitbar(0,'Saving 5DCT...');
for ind = 1: length(phaseNames)

% Load phase image 
phaseImage = metaImageRead(fullfile(patient.model_folder, '5DCT', sprintf('Deformed_pseudo_Image_phase_%d',ind)));



% Flip image if necessary
if patient.directions(patient.ref) == 0
	phaseImage = flipdim(phaseImage,3);
end
% Undo cropping done by cropConver	
imgFull = ones(patient.originalSize) * min(phaseImage(:));
imgFull(patient.cropDims(1,1):patient.cropDims(1,2),patient.cropDims(2,1):patient.cropDims(2,2),:) = phaseImage;

% Resample image back to original resolution
phaseImage = resample3Dimage_3factors(imgFull,refScanHeaders{1}.PixelSpacing(1),refScanHeaders{1}.PixelSpacing(2),1);

% Fix off-by-one image sizes due to rounding errors after resampling
if size(phaseImage,1) < refScanHeaders{1}.Rows

	imgFull = ones([refScanHeaders{1}.Rows, refScanHeaders{1}.Columns, size(phaseImage,3)]) * min(phaseImage(:));
	imgFull(1:size(phaseImage,1),1:size(phaseImage,2),:) = phaseImage;
	phaseImage = imgFull;

elseif size(phaseImage,1) > refScanHeaders{1}.Rows
	phaseImage = phaseImage(1:refScanHeaders{1}.Rows,1:refScanHeaders{1}.Columns,:);
end

% Undo scaling and intercept adjustment made when reading in dicoms using scanSync
phaseImage = (phaseImage ./ refScanHeaders{1}.RescaleSlope) - refScanHeaders{1}.RescaleIntercept;

% Make output folder
outputDir = fullfile(patient.model_folder,'5DCT DICOM',phaseNames{ind});
mkdir(outputDir);

% Write slices to dicom

	for j = 1:size(phaseImage,3)

		% Modify some tags	
		sliceName = sprintf('phase%d_slice_%03d',ind,j);
		sliceHeader = refScanHeaders{j};
		sliceHeader.SeriesNumber = ind;
		sliceHeader.SeriesDescription = phaseNames{ind};
		sliceHeader.SeriesInstanceUID = sprintf('%d',ind);
		sliceHeader.StudyDescription = '5D Research Protocol';


		% Time to save
		slice = squeeze(phaseImage(:,:,j));
		dicomwrite(uint16(slice),fullfile(outputDir, sliceName),sliceHeader);
	end

waitbar(ind/length(phaseNames),saveBar);
end
close(saveBar)

