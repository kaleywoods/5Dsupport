%% selectPhases: given an average breath and vectors for inhalation and exhalation
% amplitudes, returns corresponding (v,f) phases for image generation using 
% generate5DCT
%
% usage: [volt, flow] = selectPhases(time,voltage,exhaleAmplitudse, inhaleAmplitudes)
%
% Arguments (in):
%
% time: vector of tiems from averageBreath
% voltage: vector of bellows voltages from averageBreath
% 
% optional:
% exhaleAmplitudes: row vector of percent amplitudes to reconstruct exhalation images at. Must be in range (0 100)
% and monotonically increasing.
% inhaleAmplitde: row vector of percent amplitudes to reconstruct inhalation images at. Must be in range (0 100)
% and monotonically increasing.
%
% if no amplitudes are provided, default Siemens phases will be used (0, 25, 50, 75, 100 Ex
% and 25, 50, 75 In)
%
% Arguments (out):
% volt: bellows voltages corresponding to [exhaleAmplitdes inhaleAmplitudes] for input into 
% generate5DCT
% flow: corresponding flows


function [volt,flow] = selectPhases(varargin)

%% Handle input
time = varargin{1};
voltage = varargin{2};

if nargin > 2
	exhaleAmplitudes = varargin{3};
	inhaleAmplitde = varargin{4};
else
	exhaleAmplitudes = [0 25 50 75 100];
	inhaleAmplitudes = [25 50 75];
end


% Flip voltage for sanity
voltage = -voltage;

% Flip exhalation because of MIM weirdness
exhaleAmplitudes = exhaleAmplitudes(:)';
exhaleAmplitudes = flipdim(exhaleAmplitudes,2);

% Find point of maximum inspiration
[~,maxInd] = max(voltage);

%% Calculate exhale phases

% Voltage from maximum inspiration to end
exhaleV = prctile(voltage(maxInd:end),exhaleAmplitudes);

% Find closest indices to where these values occur 
[~,exhaleInds] = min(abs(bsxfun(@minus, exhaleV, voltage(maxInd:end)')));
exhaleInds = exhaleInds + maxInd - 1;

% Handle 0% and 100% flow calculation
exhaleF = zeros(size(exhaleV));
exhaleF(1) = (voltage(exhaleInds(1) + 1) - voltage(exhaleInds(1))) / (time(exhaleInds(1) + 1) - time(exhaleInds(1)));

exhaleF(end) = (voltage(exhaleInds(end)) - voltage(exhaleInds(end) -1 )) / (time(exhaleInds(end)) - time(exhaleInds(end)-1 ));

% Handle all other points
exhaleF(2:end-1) = arrayfun(@(x) (voltage(x + 1) - voltage(x)) / (time(x + 1) - time(x)), exhaleInds(2:end-1));

%% Okay, time for inhalation... 
inhaleV = prctile(voltage(1:maxInd), inhaleAmplitudes);
inhaleF = zeros(size(inhaleV));
% Find indices of amplitude points
[~,inhaleInds] = min(abs(bsxfun(@minus, inhaleV, voltage(1:maxInd)')));
inhaleF(1) = (voltage(inhaleInds(1) + 1) - voltage(inhaleInds(1))) / (time(inhaleInds(1) + 1) - time(inhaleInds(1)));

inhaleF(end) = (voltage(inhaleInds(end)) - voltage(inhaleInds(end) -1 )) / (time(inhaleInds(end)) - time(inhaleInds(end)-1 ));

% Handle all other points
inhaleF(2:end-1) = arrayfun(@(x) (voltage(x + 1) - voltage(x)) / (time(x + 1) - time(x)), inhaleInds(2:end-1));

% Flip signs and organize phases.  Exhale first (???)
volt = -[inhaleV exhaleV];
flow = -[inhaleF exhaleF];

