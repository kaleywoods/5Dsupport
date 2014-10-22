%% renameRegistrations

function createElastixDVF(inputDir, fileName)

%registrationDir = '/media/fiveDdata/dylan/Pig/deedsRegistrations/Registered/scan2';
%outputDir = '/media/fiveDdata/dylan/Pig/deedsRegistrations/Organized/scan2';

elementSpacing = [1 1 1];



% numRegistrations = length(deformed);
% baseFilenames = cell(numRegistrations,2);
% for ind = 1:numRegistrations
%     
%     dIndex = regexp(deformed{ind},'deformed');
%     baseFilenames{ind,1} = deformed{ind}(1:dIndex - 2);
%     [~,nIndex] = regexp(deformed{ind},'scan_');
%     rIndex = regexp(deformed{ind},'_registered');
%     baseFilenames{ind,2} = str2num(deformed{ind}(nIndex+1:rIndex-1));
%        
% end
% 
% for ind = 1:numRegistrations
    
    %mkdir(fullfile(outputDir,sprintf('out_phase%d_phase%d',ref,baseFilenames{ind,2})));
    nii = load_nii([fullfile(inputDir,fileName) '_deformed.nii']);
    metaImageWrite(nii.img,fullfile(inputDir,'result'),'ElementSpacing',elementSpacing);
    movefile(fullfile(inputDir,'result.mhd'),fullfile(inputDir,'result.0.mhd'));
    
    flowU = load_nii([fullfile(inputDir,fileName) '_flowu.nii']);
    flowV = load_nii([fullfile(inputDir,fileName) '_flowv.nii']);
    flowW = load_nii([fullfile(inputDir,fileName) '_floww.nii']);

    
    deedsDVF = zeros([size(nii.img,1) size(nii.img,2) 3 size(nii.img,3)],'single');
    deedsDVF(:,:,1,:) = flowU.img;
    deedsDVF(:,:,2,:) = flowV.img;
    deedsDVF(:,:,3,:) = flowW.img;
    
    metaImageWrite(deedsDVF,fullfile(inputDir,'deformationField'),'ElementSpacing',elementSpacing);
       

    
    

