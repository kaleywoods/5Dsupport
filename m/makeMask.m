%% makeMask
%
% makeMask(scanFiles, originalSize, cropDims, scanNumber, maskDir, staticDir)

function makeMask(scanFiles, originalSize, cropDims, scanNumber, maskDir, staticDir)

mkdir(staticDir);
maskScan = cellfun(@(x) x == scanNumber,scanFiles(:,2));
maskScanFiles = scanFiles(maskScan,1);

%% Load mask from MIM
[mask,headers] = dicomdir(maskDir);

%% Load headers of first scan
maskScanHeaders = cellfun(@dicominfo, maskScanFiles,'UniformOutput',false);
scanZpos = cellfun(@(x) x.('SliceLocation'), maskScanHeaders);
maskZpos = [headers.SliceLocation]';

%% MIM reinserts missing slices.  Find slices present in mask that are not in first scan and remove
removeSlices = ~any(bsxfun(@eq, maskZpos, scanZpos'),2);
mask(:,:,removeSlices) = [];

%% Resample mask
maskResized = resample3Dimage_3factors(mask,1/headers(1).PixelSpacing(2),1/headers(1).PixelSpacing(1),1);
maskResized(maskResized ~= 0) = 1;

%% Crop mask
% TODO: Automate cropping in this script and cropConvert
maskResized = maskResized(cropDims(1,1):cropDims(1,2),cropDims(2,1):cropDims(2,2),:);

%% Save mask
metaImageWrite(maskResized,fullfile(staticDir,'mask'),'ElementSpacing',[1 1 1]);
