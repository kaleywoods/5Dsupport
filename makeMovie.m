% Set input directory containing 4DCT .mat files
imageFolder = '/home/doconnell/clinicalPatients/patient6/model/model_params_5d_15scans/Psuedo_4DCT';
% Set output directory
outputFolder = '/home/doconnell/clinicalPatients/patient6';
outputFilename = 'movie5D.gif';
% Set number of images, coronal slice number and window/level
numImages = 40;
coronalSliceNum = 100;
lungWindow = [-300 - (1700/2), -300 + (1700/2)];


% Load images, get coronal slices
for ind = 1:numImages;
phaseName = sprintf(fullfile(imageFolder,'Deformed_pseudo_Image_phase_%d.mat'),ind);
load(phaseName);

if ind == 1
	coronalView = zeros(size(deformed_image,3),size(deformed_image,2),numImages);
end

coronalView(:,:,ind) = imrotate(squeeze(deformed_image(coronalSliceNum,:,:)),90);
end

% Crop image here if necessary
coronalView = coronalView(:,:,:);

for ind = 1:numImages

% Window/level
    frame = mat2gray(coronalView(:,:,ind),lungWindow);
% Resize image here
    frame = imresize(frame,2);
    
% Convert to indexed image
    [frameIndexed,frameMap] = gray2ind(frame,256);
   
% Write .gif.  Set delay time here 
    if ind == 1
        imwrite(frameIndexed, frameMap,fullfile(outputFolder,outputFilename),'gif','LoopCount',Inf,'DelayTime',.15);
    else
        imwrite(frameIndexed, frameMap,fullfile(outputFolder,outputFilename),'gif','WriteMode','append','DelayTime',.15);
    end
end

