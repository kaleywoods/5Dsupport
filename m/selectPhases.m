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

% Flip exhalation because reasons
exhaleAmplitudes = exhaleAmplitudes(:)';
exhaleAmplitudes = flipdim(exhaleAmplitudes,2);

% Find point of maximum inspiration
[~,maxInd] = max(voltage);

%% Calculate exhale phases

% Voltage from maximum inspiration to end
exhaleV = min(voltage(maxInd:end)) + (exhaleAmplitudes/100) .* range(voltage(maxInd:end));
[~,exhaleInds] = min(abs(bsxfun(@minus, exhaleV, voltage(maxInd:end)')));

% Find flow
exhaleF = zeros(size(exhaleV));
for ind = 1:length(exhaleV)

	if exhaleInds(ind) < 6 || exhaleInds(ind) > (length(voltage(maxInd:end)) - 5)
	exhaleF(ind) = 0;
	else
	
	flowInd = maxInd + exhaleInds(ind) - 1;
	flowRegion = [flowInd - 5: flowInd + 5];
	flowFit = polyfit(time(flowRegion),voltage(flowRegion),1);	
	exhaleF(ind) = flowFit(1);
	end
end

% Inhale

inhaleV = min(voltage(1:maxInd)) + (inhaleAmplitudes/100) .* range(voltage(1:maxInd)); 
[~,inhaleInds] = min(abs(bsxfun(@minus, inhaleV, voltage(1:maxInd)')));

inhaleF = zeros(size(inhaleV));
for ind = 1:length(inhaleV)

	if inhaleInds(ind) < 6  || inhaleInds(ind) > maxInd - 5
	exhaleF(ind) = 0;
	else
	
	flowInd = inhaleInds(ind);
	flowRegion = [flowInd - 5: flowInd + 5];
	flowFit = polyfit(time(flowRegion),voltage(flowRegion),1);	
	inhaleF(ind) = flowFit(1);
	end

end

% Flip signs and organize phases.  exhale first (???)
volt = -[flipdim(exhaleV,2) flipdim(inhaleV,2)];
flow = -[flipdim(exhaleF,2) flipdim(inhaleF,2)];
