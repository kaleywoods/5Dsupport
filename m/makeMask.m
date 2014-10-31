%% makeMask
%
% makeMask(scanFiles, originalSize, cropDims, zExtent, scanNumber, maskDir, staticDir)

function makeMask(scanFiles, originalSize, cropDims, zExtent, scanNumber, maskDir, staticDir)


mkdir(staticDir);
maskScan = cellfun(@(x) x == scanNumber,scanFiles(:,2));
maskScanFiles = scanFiles(maskScan,1);

%% Load mask from MIM
[mask,headers] = dicomdir(maskDir);
maskZpos = [headers.SliceLocation]';

%% Check output of scanSync -- was the reference scan interpolated?
if (length(zExtent) == 1)

% If not, handle

% Load headers of first scan
maskScanHeaders = cellfun(@dicominfo, maskScanFiles,'UniformOutput',false);

% Get z positions of the reference scan
scanZpos = cellfun(@(x) x.('SliceLocation'), maskScanHeaders);

%% MIM reinserts missing slices.  Find slices present in mask that are not in first scan and remove
removeSlices = ~any(bsxfun(@eq, maskZpos, scanZpos'),2);
mask(:,:,removeSlices) = [];


else

%% Scans were resampled, handle


% Treat the scan as lying along a uniform grid in Z from 1:numSlices
% and find the positions to intperolate at (zExtent) relative to this grid.
% Add 1 because matlab indexing

z = (zExtent - maskZpos(1)) + 1;
% Set up grid
x = [1:headers(1).Columns]';
y = [1:headers(1).Rows]';

% Interpolate image
% Default: mirt3d
% Uncomment to use mirt3d
% ba_interp (slower, potentially more accurate)
%[Xi,Yi,Zi] = ndgrid(x,y,z);
%Xi = double(Xi);
%Yi = double(Yi);
%Zi = double(Zi);
%scanImage = ba_interp3(scanImage,Yi,Xi,Zi,'cubic');

% Comment out if you want to use ba_interp
[X,Y,Z] = meshgrid(x,y,z);
X = double(X);
Y = double(Y);
Z = double(Z);
mask = mirt3D_mexinterp(mask,X,Y,Z);

end

%% Resample mask
maskResized = resample3Dimage_3factors(mask,1/headers(1).PixelSpacing(2),1/headers(1).PixelSpacing(1),1);
maskResized(maskResized ~= 0) = 1;

%% Crop mask
% TODO: Automate cropping in this script and cropConvert
maskResized = maskResized(cropDims(1,1):cropDims(1,2),cropDims(2,1):cropDims(2,2),:);

%% Save mask
metaImageWrite(maskResized,fullfile(staticDir,'mask'),'ElementSpacing',[1 1 1]);

