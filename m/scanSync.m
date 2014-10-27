function scanSync(bellowsDataFilename, scanDirectory, outputDirectory, numberOfScans)

% scanSync(bellowsDataFilename, scanDirectory, outputDirectory,
% numberOfScans)
%
% Writes raw image files and data structures from bellows signal file and
% scan dicoms for use with the 5D-Toolbox.
%
% Dependencies: MATLAB Image Processing Toolbox, selectdata, time2sec, resample3Dimage_3factors,
% metaImageWrite
%
% Loads a file containing a bellows signal along with a corresponding series
% of scans. The scans are synchronized to the bellows signal, converted to
% .mhd format and written to the output directory.  The bellows voltage
% information for each scan is written to a .mat file in the output
% directory.  Set the output folder as patient.folder_static for this
% patient in choose_patient_toolbox.m
%
% Dicom images must be in scanDirectory or one of its subfolders.
%
% Requries user to select a region of the bellows signal containing the
% scan series.

%% Import bellows data
bellows = importdata(bellowsDataFilename);

% Set data channels
channels.time = 1;
channels.voltage = 2;
channels.xrayOn = 5;
channels.mouthPressure = 2;
channels.bloodPressure = 5;

% Set bellows sampling rate
bellowsSampleRate = .01;

%% Threshold x-ray on signal

xrayOn = bellows(:,channels.xrayOn);
xrayOn = -xrayOn;
thresholdMax = 1.75;
xrayOn(xrayOn > thresholdMax) = 5;
xrayOn(xrayOn < thresholdMax) = 0;

%% Plot x-ray on vs. time and get user input to select data range

selectionPlot = figure;
set(selectionPlot,'units','normalized','position', [0.1000    0.1000    0.8100    0.8100]);
ylim([-10 15]);
hold on
plot(bellows(:,channels.time),xrayOn,'b');

xlabel('Time');
ylabel('Scaled X-Ray On Signal');
title(sprintf('Select a range that contains %d full scans.',numberOfScans),'FontSize',20);
pointList = selectdata('sel','r','Verify','off','Pointer','crosshair');
hold off
close(selectionPlot);

% Use only bellows data within selected range
dataRange(1) = min(pointList);
dataRange(2) = max(pointList);


bellowsTime = bellows(dataRange(1):dataRange(2),channels.time);
bellowsVoltage = bellows(dataRange(1):dataRange(2),channels.voltage);
xrayOn = xrayOn(dataRange(1):dataRange(2));


% Plot bellows voltage and x-ray on vs. time for selected data range

xrayBellowsPlot = figure;
set(xrayBellowsPlot,'units','normalized','position', [0.1000    0.1000    0.8100    0.8100]);
plot(bellowsTime,bellowsVoltage,'r')
hold on
plot(bellowsTime,xrayOn,'b');
legend('Bellows Voltage', 'X-Ray On','Location','NorthEastOutside');
title('Bellows Voltage and X-Ray On');
xlabel('Time (s)')
hold off


%% Seperate scans on bellows signal using x-ray

% Get indices of large negative and positive jump discontinuities in x-ray on signal
xrayOnDiffs = diff(xrayOn);

startIndices = find(xrayOnDiffs < -4) + 1;
stopIndices = find(xrayOnDiffs > 4 );

% Check number of large voltage jumps against number of scans
if (length(startIndices) ~= numberOfScans)  || (length(stopIndices) ~= numberOfScans) 
    error('The number of scans computed from x-ray on signal does not match number of scans entered. Check the threshold values for the x-ray on signal.');
end
    
% Get indices of entries in xrayOn which occur during scans
scanIndices = arrayfun(@(x,y) [x:y], startIndices, stopIndices, 'UniformOutput', false); 
scanIndices = [scanIndices{:}]';


% Get bellows voltage during scans.  Pad with NaN for cases with unequal
% scan lengths

maxScanLength = max(stopIndices - startIndices);

scanBellowsVoltage = arrayfun(@(x,y) bellowsVoltage(x:y - 1), startIndices, stopIndices, 'UniformOutput', false);
scanBellowsVoltage = cell2mat(cellfun(@(x) cat(1,x,nan(maxScanLength - length(x),1)), scanBellowsVoltage, 'UniformOutput',false));
scanBellowsVoltage = reshape(scanBellowsVoltage, maxScanLength, numberOfScans);

scanBellowsTime = arrayfun(@(x,y) bellowsTime(x:y-1), startIndices, stopIndices, 'UniformOutput', false);
scanBellowsTime = cell2mat(cellfun(@(x) cat(1,x,nan(maxScanLength - length(x),1)), scanBellowsTime, 'UniformOutput',false));
scanBellowsTime = reshape(scanBellowsTime, maxScanLength, numberOfScans);

%% Create output directory
mkdir(outputDirectory);

%% Load scan header files
[allScanHeaders, scanDirectoryDicoms] = getDicomHeaders(scanDirectory,'Loading DICOM headers...');

% Store header, series number and filename for later sorting

try
allScanHeaders = cat(2,allScanHeaders,cellfun(@(x) x.('SeriesNumber'), allScanHeaders(:,1), 'UniformOutput', false));
allScanHeaders = cat(2,allScanHeaders,cellfun(@(x) time2sec(str2num(x.('AcquisitionTime'))), allScanHeaders(:,1), 'UniformOutput', false));
allScanHeaders = cat(2,allScanHeaders,scanDirectoryDicoms);
end

% Check for subfolders
scanFoldersDir = dir(scanDirectory);
scanFoldersDir(logical(cell2mat(cellfun(@(x) ismember(x,{'.','..'}), {scanFoldersDir.name}, 'UniformOutput', false)))) = [];
scanSubfolders = {scanFoldersDir([scanFoldersDir.isdir]).name};

% Initialize waitbar
if ~isempty(scanSubfolders)
loadHeaders = waitbar(0,'Scanning subdirectories for DICOM files...'); 

% Loop over all subfolders and search for dicom files
	for ind = 1:length(scanSubfolders)

	[subfolderHeaders, subDirectoryDicoms] = getDicomHeaders(fullfile(scanDirectory,scanSubfolders{ind}));

	try
	% Read headers and store filename, series number, acquisition time.
	subfolderHeaders = cat(2,subfolderHeaders, cellfun(@(x) x.('SeriesNumber'), subfolderHeaders(:,1), 'UniformOutput', false));
	subfolderHeaders = cat(2,subfolderHeaders, cellfun(@(x) time2sec(str2num(x.('AcquisitionTime'))), subfolderHeaders(:,1), 'UniformOutput', false));
	subfolderHeaders = cat(2,subfolderHeaders,subDirectoryDicoms);

	% Append headers to scanHeader
	allScanHeaders = cat(1,allScanHeaders,subfolderHeaders);
	end

	waitbar((ind/length(scanSubfolders)),loadHeaders);
    
	end
close(loadHeaders)
end

% Sort headers according to acquisition time.
allScanHeaders = sortrows(allScanHeaders,3);

% Get list of series numbers
seriesNumbers = unique(cell2mat(allScanHeaders(:,2)));

%% Check for topogram, remove
firstScan = cell2mat(allScanHeaders(:,2));
firstScan = logical(firstScan == seriesNumbers(1));

if nnz(firstScan) == 1
allScanHeaders(firstScan,:) = [];
end

%% Consider only first (numberOfScans) scans
%if numberOfScans < 25
%allScanHeaders(find([allScanHeaders{:,2}] == seriesNumbers(numberOfScans + 1), 1, 'first'):end,:) = [];
%end

%%% Fix unequal numbers of slices or misaligned scans
%
%% Get count of slices for each scan
%sliceCounts = arrayfun(@(x) nnz(cell2mat(allScanHeaders(:,2)) == x), seriesNumbers);
%%
%%% Check for different slice numbers
%
%if any(diff(sliceCounts))
%warning('Scans do not have equal numbers of slices. Removing errant slices...');
%end
%
%%% Get z positions of each scan
%zPositions = cell2mat(cellfun(@(x) x.('SliceLocation'),allScanHeaders(:,1),'UniformOutput',false));
%zPositionsUnique = unique(zPositions);
%
%%% For each unique position, verify that it occurs in each scan
%numOccurences = sum(bsxfun(@eq,zPositionsUnique,zPositions'), 2);
%removeSlices = numOccurences ~= numberOfScans;
%
%%% If slice position doesn't occur in all scans, remove it
%removeHeaders = any(bsxfun(@eq,zPositions,zPositionsUnique(removeSlices)'),2);
%allScanHeaders(removeHeaders,:) = [];

%% Currently does not use paralell toolbox due to memory issues while
%% resampling scans.

% Save filenames and scan numbers of dicom slices which were used
scanLabels = zeros(length(allScanHeaders),1);
for ind = 1:length(seriesNumbers)
	scanMask = cellfun(@(x) x == seriesNumbers(ind),allScanHeaders(:,2));
	scanLabels(scanMask) = ind;
end

scanFiles = [allScanHeaders(:,4), arrayfun(@(x) x, scanLabels, 'UniformOutput',false)];
save(fullfile(outputDirectory,'scanFiles'),'scanFiles');

%% Process scan images

%Initialize waitbar
loadImages = waitbar(0, 'Synchronizing scans to bellows signal...');
% Load images
for ind = 1:numberOfScans

% Set series number and indices within allScanHeaders
seriesNumber = seriesNumbers(ind);    
seriesInd = logical(cell2mat(arrayfun(@(x) isequal(seriesNumber,x), [allScanHeaders{:,2}], 'UniformOutput', false)))';

% Set headers, acquisition times and slice filenames
scanHeaders = allScanHeaders(seriesInd,1);
acquisitionTimes = cell2mat(allScanHeaders(seriesInd,3));
sliceFileNames = allScanHeaders(seriesInd,4);

% Extract slice acquisition time and z position, get scan duration and
% direction.  Set direction as 1 or 0.
zPositions = cell2mat(cellfun(@(x) x.('SliceLocation'), scanHeaders, 'UniformOutput', false))';

scanDuration = acquisitionTimes(end) - acquisitionTimes(1);
%scanDirection = (zPositions(end) - zPositions(1)) < 0;
scanDirection = (zPositions(end) - zPositions(1)) > 0;
% Account for x-ray warm up.
xrayWarmupDelay = (stopIndices(ind) - startIndices(ind)) / (1/bellowsSampleRate) - abs(scanDuration);
xrayWarmup = ceil((xrayWarmupDelay * (1/bellowsSampleRate)) / 2);

bellowsVoltageXrayOn = scanBellowsVoltage(xrayWarmup + 1 : end - xrayWarmup - 1, ind);
bellowsTimeXrayOn = scanBellowsTime(xrayWarmup + 1 : end - xrayWarmup - 1, ind);

% Normalize bellows and acquisition times
acquisitionTimesNorm = acquisitionTimes - acquisitionTimes(1);
bellowsTimeXrayOnNorm = bellowsTimeXrayOn - bellowsTimeXrayOn(1);

% Interpolate to find bellows time corresponding to slice acquisition time
bellowsVoltageSlices = interp1(bellowsTimeXrayOnNorm,bellowsVoltageXrayOn,acquisitionTimesNorm,'pchip');

% Load image
scanImage = cell2mat(cellfun(@(x) dicomread(x), sliceFileNames, 'UniformOutput',false)');  
scanImage = reshape(scanImage, scanHeaders{1}.Height, scanHeaders{1}.Width, length(scanHeaders));

% Resample image to 1x1x1
scanImage = resample3Dimage_3factors(scanImage,(1/scanHeaders{1}.PixelSpacing(1)), (1/scanHeaders{1}.PixelSpacing(2)), 1);

% Rescale image according to slope and intercept
scanImage = (scanImage .* scanHeaders{1}.RescaleSlope) + scanHeaders{1}.RescaleIntercept;

% Check scan direction, flip image and slice bellows voltage accordingly

if scanDirection < 1

scanImage = flipdim(scanImage, 3);
bellowsVoltageSlices = flipdim(bellowsVoltageSlices,1);

end
    
%% Change variable names to interface with 5D Toolbox

bvp = bellowsVoltageSlices;
scan_time = acquisitionTimes;
direction = scanDirection;

% ECG voltage not currently implemented, but is requried as an argument to 
ecgvp = bvp;

%% Save variables and images

save(fullfile(outputDirectory,sprintf('image_scan_%d',ind)), 'bvp', 'scan_time', 'direction', 'ecgvp');
metaImageWrite(scanImage,fullfile(outputDirectory,sprintf('scan_%d_cut',ind)), 'ElementSpacing', [1 1 scanHeaders{1}.SliceThickness])

waitbar((ind/length(seriesNumbers)), loadImages);
end

close(loadImages)





