%% saveDicom: Write an image volume to dicom format.  The headers of the 
% first fast helical scan are modified and used.
%
% Arguments(in)
%
% image: image
% outputDir: where to put the dicom files

function saveDicom(image, outputDir, patient)

% Load cropping data
crop = load(fullfile(patient.folder,'crop.mat'));
originalSize = crop.originalSize;
cropDims = crop.cropDims;
scanFiles = load(fullfile(patient.folder_static,'scanFiles.mat'));
scanFiles = scanFiles.scanFiles;

% Load the headers from the first scan
firstScanInds = [scanFiles{:,2}] == 1;
refScanHeaders = cellfun(@dicominfo, scanFiles(firstScanInds,1), 'uni', false);

% Flip image if necessary
if patient.directions(patient.ref) == 0
	image = flipdim(image,3);
end

% Undo cropping done by cropConver	
imgFull = ones(originalSize) * min(image(:));
imgFull(cropDims(1,1):cropDims(1,2),cropDims(2,1):cropDims(2,2),:) = image;

% Resample image back to original resolution
image = resample3Dimage_3factors(imgFull,refScanHeaders{1}.PixelSpacing(1),refScanHeaders{1}.PixelSpacing(2),1);

% Fix off-by-one image sizes due to rounding errors after resampling
if size(image,1) < refScanHeaders{1}.Rows

	imgFull = ones([refScanHeaders{1}.Rows, refScanHeaders{1}.Columns, size(image,3)]) * min(image(:));
	imgFull(1:size(image,1),1:size(image,2),:) = image;
	image = imgFull;

elseif size(image,1) > refScanHeaders{1}.Rows
	image = image(1:refScanHeaders{1}.Rows,1:refScanHeaders{1}.Columns,:);
end

% Undo scaling and intercept adjustment made when reading in dicoms using scanSync
image = (image ./ refScanHeaders{1}.RescaleSlope) - refScanHeaders{1}.RescaleIntercept;

% Make output folder
mkdir(outputDir);
saveBar = waitbar(0,'Saving image...');
% Write slices to dicom

	for j = 1:size(image,3)

		% Modify some tags	
		sliceName = sprintf('slice%03d',j);
		sliceHeader = refScanHeaders{j};
		sliceHeader.SeriesNumber = 1;
		sliceHeader.SeriesDescription = 'Reference Image';
		sliceHeader.SeriesInstanceUID = '1';
		sliceHeader.StudyDescription = '5D Clinical Protocol';


		% Time to save
		slice = squeeze(image(:,:,j));
		dicomwrite(uint16(slice),fullfile(outputDir, sliceName),sliceHeader);
		try
		waitbar(j/size(image,3),saveBar);
		end
	end


try
	close(saveBar);
end

