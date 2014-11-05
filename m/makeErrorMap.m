%% makeErrorMap: Using the reconstruction errors for each original scan,
% create a single error map in the reference image geoemetry. Currently,
% the approximate 75th percentile error value is taken
%
% Arguments (in)
% patient: patient data structure from 5D Toolbox


function makeErrorMap(patient)

% Load all reconstruction errors
reconError = zeros([size(patient.static), (patient.scans -1)],'single');
for ind = 2:patient.scans
	reconError(:,:,:,ind-1) = metaImageRead(fullfile(patient.folder_reconError,sprintf('scan%d.mhd',ind)));
end


% Get approximate 75th percentile errors
errorPercentile = 75;
nthWorst = patient.scans -1 - floor(prctile([1:(patient.scans - 1)], errorPercentile));

% Sort matrix of errors;
reconError = sort(reconError,4,'descend');

% Dirty hack to avoid sorting:
% Find the max along the 4th dimension, set to 0.  Repeat n times.
% TODO: Find a better way

%for ind = 1:nthWorst
%
%	if ind == nthWorst;
%	errorMap = max(reconError,[],4);
%	else
%	[~,maxInds] = max(reconError,[],4);
%	reconError(maxInds) = 0;
%	end
%
%end

% Take approximate 75th percentile
errorMap = reconError(:,:,:,nthWorst);
% Mask lungs
errorMap = errorMap .* patient.static_mask;

% Save error map
metaImageWrite(errorMap,fullfile(patient.folder,'errorMap'),'ElementSpacing',[1 1 1]);
