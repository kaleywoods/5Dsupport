%% invertDVF

function [invY, invX, invZ] = invertDVF(vY,vX,vZ)


numIterations = 10;

% Eliminate singlton dimensions and cast as double
vY = squeeze(double(vY));
vX = squeeze(double(vX));
vZ = squeeze(double(vZ));

% Set up grid of voxel coordinates
[X, Y, Z] = ndgrid([1:size(vY,1)],[1:size(vY,2)],[1:size(vY,3)]);

% Initialize first estimate of inverse DVF to 0
invX = zeros(size(X));
invY = zeros(size(Y));
invZ = zeros(size(Z));

% Form 4-D matrix to represent DVF.
% In this form, ba_interp3 interpolates each component simultaneously.
dvf = cat(4,vX,vY,vZ);


for ind = 1: numIterations

% Get inverse DVF using linear interpolation

% MATLAB implementation (slow)
%  invXn = - interpn(dvfX, X + invX, Y + invY, Z + invZ);
%  invYn = - interpn(dvfY, X + invX, Y + invY, Z + invZ);
%  invZn = - interpn(dvfZ, X + invX, Y + invY, Z + invZ);

% mirt3D (Fast, but does each component seperately)
% invXn = - mirt3D_mexinterp(dvfX, X + invX, Y + invY, Z + invZ);
% invYn = - mirt3D_mexinterp(dvfY, X + invX, Y + invY, Z + invZ);
% invZn = - mirt3D_mexinterp(dvfZ, X + invX, Y + invY, Z + invZ);


inv = - ba_interp3(dvf,Y + invY, X + invX, Z + invZ, 'linear');
invX = inv(:,:,:,1);
invY = inv(:,:,:,2);
invZ = inv(:,:,:,3);

end




