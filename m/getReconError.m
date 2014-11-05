%% getReconError: Get the original scan reconstruction error.
% Calculates the magnitude of deformation vector fields written
% by deform_images_psuedo_originalscans_toolbox after registration
% of model generated pseudoscans to originally acquired scans. 
% These magnitudes are then deformed to the reference image 
% geometry.
%
% Arguments (in)
% patient: patient data structure from 5D Toolbox

function getReconError(patient)

mkdir(patient.folder_reconError);
pseudoScanDir = fullfile(patient.model_folder,'Psuedo_scans');
numScans = patient.scans;

for ind = 2:numScans

	% Load error map
	errorMap = metaImageRead(fullfile(pseudoScanDir,sprintf('scan%d',ind),'Registration','deformationField.mhd'));
	
	% Take magnitude of deformation vectors as voxel error
	errorMap = bsxfun(@hypot, squeeze(errorMap(:,:,1,:)), bsxfun(@hypot, squeeze(errorMap(:,:,2,:)),squeeze(errorMap(:,:,3,:))));

	% Load deformation field going to reference geometry
	refDVF = metaImageRead(fullfile(patient.folder_elastix,sprintf('out_phase%d_phase%d',patient.ref,ind),'deformationField.mhd'));

	% Deform image to reference geometry
	errorMap = deform_image_mirt3d(errorMap, squeeze(refDVF(:,:,2,:)), squeeze(refDVF(:,:,1,:)), squeeze(refDVF(:,:,3,:)));

	% Save error map
	metaImageWrite(errorMap,fullfile(patient.folder_reconError,sprintf('scan%d',ind)),'ElementSpacing',[1 1 1]);

end


