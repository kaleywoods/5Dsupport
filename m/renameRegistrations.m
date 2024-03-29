%% renameRegistrations: Converts output of the deedsMIND registration algorithm
% to the format used by elastix for use by the 5D Toolbox.
%
% Arguments (in):
% registrationDir: directory containing deedsMIND output in .nii format
% outputDir: where to put the converted images and deformation fields
% refScanNumber: number of the scan which was used as the reference image


function renameRegistrations(registrationDir, outputDir, refScanNumber)

mkdir(outputDir)


% Set reference scan number and voxel size
ref = refScanNumber;
elementSpacing = [1 1 1];

% Look for output files from deedsMIND
deformed = dir(fullfile(registrationDir,'*deformed.nii'));
deformed = {deformed.name}';
numRegistrations = length(deformed);
baseFilenames = cell(numRegistrations,2);

% Process images
renameBar = waitbar(0,'Reformatting images...');

for ind = 1:numRegistrations
    
    dIndex = regexp(deformed{ind},'deformed');
    baseFilenames{ind,1} = deformed{ind}(1:dIndex - 2);
    [~,nIndex] = regexp(deformed{ind},'scan_');
    rIndex = regexp(deformed{ind},'_registered');
    baseFilenames{ind,2} = str2num(deformed{ind}(nIndex+1:rIndex-1));

   	 % Compatability with parallelDeeds scritpt
    	if isempty(baseFilenames{ind,2})
	baseFilenames{ind,2} = str2num(cell2mat(regexp(deformed{ind},'\d','match')));
	end
       
end
for ind = 1:numRegistrations
    
    mkdir(fullfile(outputDir,sprintf('out_phase%d_phase%d',ref,baseFilenames{ind,2})));
    nii = load_nii(fullfile(registrationDir,deformed{ind}));
    metaImageWrite(nii.img,fullfile(outputDir,sprintf('out_phase%d_phase%d',ref,baseFilenames{ind,2}),'result'),'ElementSpacing',elementSpacing);
    movefile(fullfile(outputDir,sprintf('out_phase%d_phase%d',ref,baseFilenames{ind,2}),'result.mhd'),fullfile(outputDir,sprintf('out_phase%d_phase%d',ref,baseFilenames{ind,2}),'result.0.mhd'));
    
    flowU = load_nii(fullfile(registrationDir,[baseFilenames{ind,1} '_flowu.nii']));
    flowV = load_nii(fullfile(registrationDir,[baseFilenames{ind,1} '_flowv.nii']));
    flowW = load_nii(fullfile(registrationDir,[baseFilenames{ind,1} '_floww.nii']));

    
    deedsDVF = zeros([size(nii.img,1) size(nii.img,2) 3 size(nii.img,3)],'single');

    deedsDVF(:,:,1,:) = flowU.img;
    deedsDVF(:,:,2,:) = flowV.img;
    deedsDVF(:,:,3,:) = flowW.img;
    
    metaImageWrite(deedsDVF,fullfile(outputDir,sprintf('out_phase%d_phase%d',ref,baseFilenames{ind,2}),'deformationField'));
       
    try
	    waitbar(ind/numRegistrations,renameBar);
    end
end
   try
	  close(renameBar);
  end

    

