%%dicomdir
% [image3d, headers] = dicomdir(folderName) imports a contiguous series of dicom
% image slices and their headers.
% Assumes that directories contain only dicom files and that each directory
% contains a single scan.

function [image3d, headers] = dicomdir(folderName)
%% Get image series filenames
%NB: This assumes that the only .dcm files in the folder are the image
%slices

dicomDir = dir(fullfile(folderName,'*.dcm'));
if (isempty(dicomDir))
    dicomDir = dir(folderName);
end
dicomDirNames = setdiff({dicomDir.name},{'.','..'});

%% Import images and headers
for i = 1:numel(dicomDirNames),
    slicesUnsorted{i} = dicomread(fullfile(folderName,dicomDirNames{i}));
    headersUnsorted(i) = dicominfo(fullfile(folderName,dicomDirNames{i}));
end

%% Sort images by z position
% ***Change to sort by time

% Get z location of each slice
imagePositions = [headersUnsorted.ImagePositionPatient]';
sliceLocatons = imagePositions(:,3);

% Match each slice with its z location
imageOrder = [[1:1:length(headersUnsorted)]', sliceLocatons];

% Sort by slice z location
imageOrderSorted = sortrows(imageOrder, 2);

%% Return sorted images and headers

for i = 1:length(headersUnsorted)
    headers(i) = headersUnsorted(imageOrderSorted(i,1));
    slices(i) = slicesUnsorted(imageOrderSorted(i,1));
end

%Convert cell array of image slices into 3d image
image3d = cellslice3d(slices);

% Rescale image
image3d = (image3d .* headers(1).RescaleSlope) + headers(1).RescaleIntercept;
