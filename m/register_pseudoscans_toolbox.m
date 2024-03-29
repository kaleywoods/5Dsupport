function register_pseudoscans_toolbox(patient, scan)
% [folder] = uigetdir('Select Folder to Analyse');       % This overwrited dicom_dir saved for the data may be processed on another PC
folder_static= patient.folder_static;
% model_folder = 'E:\Patient_Data_E\pt2\pt2\model_params_5d_25scans\Psuedo_scans';
 scan_folder = [patient.model_folder '/Psuedo_scans' sprintf('/scan%d',scan)];

%% Convert pseudoscan and original scan to .nii
mhdPathPseudo = fullfile(scan_folder,sprintf('pseudo_scan%d.mhd',scan));
niiPathPseudo = fullfile(scan_folder,sprintf('pseudo_scan%d.nii',scan));
niiConvert(mhdPathPseudo,niiPathPseudo);

%mhdPathPseudo = fullfile(scan_folder,sprintf('pseudo_scan%d.mhd',scan));
%niiPathPseudo = fullfile(scan_folder,sprintf('pseudo_scan%d.nii',scan));
%niiConvert(mhdPathPseudo,niiPathPseudo); 

% For now, use preexisting .nii files
niiPathOriginal = fullfile(patient.folder_nii,sprintf('scan_%d_cut.nii',scan));
  
% fixed = ['"' scan_folder sprintf('/pseudo_scan%d.mhd', scan) '"']
% fixed_mask = ['"' scan_folder sprintf('/pseudo_mask%d.mhd', scan) '"']  
% moving=['"' folder_static sprintf('/scan_%d_cut.mhd', scan) '"']

%% Register images using deeds MIND 
mkdir(fullfile(scan_folder,'Registration'));
deedsOut = fullfile(scan_folder,'Registration','deedsOut');

deedsCmd = ['deedsMIND ' '"' niiPathPseudo '" ' '"' niiPathOriginal '" ' '"' deedsOut '" ' '2.0 ' '128.0'];

% elastix_cmd=['elastix -f ' fixed  ' -fMask ' fixed_mask ' -m ' moving ' -out "'  out  '" -p ' param1] 
%  elastix_cmd=['elastix -f ' fixed  ' -fMask ' fixed_mask ' -m ' moving ' -out ' '"' out '"' ' -p ' param1 ' -p ' param2  ' -p ' param3] 

[status result]=system(deedsCmd)

% Resize flow
resizeCmd = ['resizeFlow ' '"' deedsOut '"'];

[status2 result2] = system(resizeCmd)
%  transform_param=['"' out '\TransformParameters.0.txt' '"']
% %  transform_param2=['"' out '\TransformParameters.2.txt' '"']
% 
% transformix_cmd=['transformix -def all -out ' '"' out '"' ' -tp ' transform_param] 
% % [status result]=system(transformix_cmd, '-echo');
% [status result]=system(transformix_cmd);

createElastixDVF(fullfile(scan_folder,'Registration'),'deedsOut');


