%% saveDicom: Write an image volume to dicom format.  The headers of the 
% first fast helical scan are modified and used.
%
% saveDicom(image, patient, outputDir, scanNumber, seriesDescription)
%
% Arguments(in)
%
% image: image
% patient: patient data structure
% outputDir: where to put the dicom files
% scanNumber: (optional) scan number to grab the dicom headers from.  defaults to
% the reference scan
% seriesDescription: (optional): Series description.  Defaults to "Reference Image"

function saveDicom(varargin)
image = varargin{1};
patient = varargin{2};
outputDir = varargin{3};

if nargin > 3
scanNumber = varargin{4};
else
scanNumber = patient.ref;
end

if nargin > 4
seriesDescription = varargin{5};
else
seriesDescription = 'Reference Image';
end
% Load cropping data
crop = load(fullfile(patient.folder,'crop.mat'));
originalSize = crop.originalSize;
cropDims = crop.cropDims;
scanFiles = load(fullfile(patient.folder_static,'scanFiles.mat'));
scanFiles = scanFiles.scanFiles;

% Load the headers from the reference scan
firstScanInds = [scanFiles{:,2}] == patient.ref;
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

if scanNumber == patient.ref 
	for j = 1:size(image,3)

		% Modify some tags	
		sliceName = sprintf('slice%03d',j);
		sliceHeader = refScanHeaders{j};
		sliceHeader.SeriesNumber = 1;

		sliceHeader.StudyID = num2str(str2num(sliceHeader.StudyID) + 1);
		sliceHeader.SeriesDescription = seriesDescription;
		sliceHeader.SeriesInstanceUID = '1';
		sliceHeader.StudyDescription = '5D Clinical Protocol';


		% Time to save
		slice = squeeze(image(:,:,j));
		dicomwrite(uint16(slice),fullfile(outputDir, sliceName),sliceHeader);
		try
		waitbar(j/size(image,3),saveBar);
		end
	end

else

scanInds = [scanFiles{:,2}] == scanNumber;
scanInd = find(scanInds,1);
altScanHeader = dicominfo(scanFiles{scanInd,1});

	for j = 1:size(image,3)

		% Modify some tags	
		sliceName = sprintf('slice%03d',j);
		sliceHeader = refScanHeaders{j};
		sliceHeader.SeriesNumber = scanNumber;

		sliceHeader.StudyID = altScanHeader.StudyID;
		sliceHeader.StudyInstanceUID = altScanHeader.StudyInstanceUID;
		sliceHeader.SeriesDescription = seriesDescription;
		sliceHeader.SeriesInstanceUID = num2str(scanNumber);
		sliceHeader.StudyDescription = '5D Clinical Protocol';


		% Time to save
		slice = squeeze(image(:,:,j));
		dicomwrite(uint16(slice),fullfile(outputDir, sliceName),sliceHeader);
		try
		waitbar(j/size(image,3),saveBar);
		end
	end
end
try
	close(saveBar);
end

