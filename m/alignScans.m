%% alignScans
%
% Handle misaligned scans and scans of unequal length during
% syncrhonization to the bellows signal.


function alignScans(scanData, outputDirectory) 

% What is the largest range of Z positions that falls within every scan?

% Once we've found the range, find the set of z positions common to the most
% scans (or just reference scan), and resample the other images (and their bellows
% voltage) on that interval.
%
%

%% Find largest range of Z positions common to all scans

numScans = length(scanData);

% Assume that all scans have the same slice thickness
sliceThickness = scanData(1).headers{1}.SliceThickness;

% Get extent in Z of all scans
zExtent = zeros(2,numScans);
for ind = 1:numScans
zExtent(:,ind) = sort([scanData(ind).headers{1}.SliceLocation scanData(ind).headers{end}.SliceLocation]');
end

% Take the largest min Z and smallest max Z
zExtent = [max(zExtent(1,:)); min(zExtent(2,:))];

% Set up grid of Z positions to interpolate at

zExtent = [zExtent(1):sliceThickness:zExtent(2)];

%% Interpolate all images and bellows signals at these z ranges

alignBar = waitbar(0,'Aligning and saving scans...');
for ind = 1:numScans

% Load image
scanImage = cell2mat(cellfun(@dicomread, scanData(ind).filenames, 'UniformOutput',false)');  
scanImage = reshape(scanImage, scanData(ind).headers{1}.Height, scanData(ind).headers{1}.Width, length(scanData(ind).headers));
scanImage = double(scanImage);

% Get z positions
scanZ = cellfun(@(x) x.('SliceLocation'), scanData(ind).headers);

% Alias structure fields for convenience
scanVolt = scanData(ind).voltage;
scanTime = scanData(ind).time;
scanHeaders = scanData(ind).headers;
scanDirection = scanData(ind).direction;

% Flip image, z positions, and bellows if necessary
if scanData(ind).direction < 1

	scanImage = flipdim(scanImage,3);
	scanZ = flipdim(scanZ,1);
	scanVolt = flipdim(scanVolt,1);
	scanFlipped = true;
else
	scanFlipped = false;
end

numSlices = length(scanZ);


% Check if interpolation is needed
if ~isequal(scanZ, zExtent);

% Treat the scan as lying along a uniform grid in Z from 1:numSlices
% and find the positions to intperolate at (zExtent) relative to this grid.
% Add 1 because matlab indexing

z = (zExtent - scanZ(1)) + 1;

% Set up grid
x = [1:scanData(1).headers{1}.Columns]';
y = [1:scanData(1).headers{1}.Rows]';

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
scanImage = mirt3D_mexinterp(scanImage,X,Y,Z);

% Interpolate bellows voltage
scanVolt = interp1(scanZ, scanVolt, zExtent, 'pchip');

% Interpolate time
scanTime = interp1(scanZ, scanTime, zExtent, 'pchip');

end

% Resample image to 1x1x1
scanImage = resample3Dimage_3factors(scanImage,(1/scanHeaders{1}.PixelSpacing(1)), (1/scanHeaders{1}.PixelSpacing(2)), 1);

% Rescale image according to slope and intercept
scanImage = (scanImage .* scanHeaders{1}.RescaleSlope) + scanHeaders{1}.RescaleIntercept;

% Change variable names to interface with 5D Toolbox

bvp = scanVolt;
scan_time = scanTime;
direction = scanDirection;

% ECG voltage not currently implemented, but is requried as an argument to 
ecgvp = bvp;

% Save variables and images

save(fullfile(outputDirectory,sprintf('image_scan_%d',ind)), 'bvp', 'scan_time', 'direction', 'ecgvp');
metaImageWrite(scanImage,fullfile(outputDirectory,sprintf('scan_%d_cut',ind)), 'ElementSpacing', [1 1 scanHeaders{1}.SliceThickness])

try
waitbar((ind/numScans),alignBar);
end

end

try
close(alignBar);
end

