%% averageBreath: calculate an average breath based on a graphically specified region
% of the patient's breathing trace.  The average breath can then be sampled for 
% (v,f) phases to generate images at using generate5DCT
%
% usage: [time, voltage] = averageBreath(bellowsDataFilename)
% 
% dependencies: selectdata, consolidator
%
% Arguments (in):
% bellowsDataFilename: self explanatory
%
% Arguments (out):
% time: 1 x 500 vector of time points, with the same spacing as the bellows sample rate (.01 s).
% voltage: 1x 500 vector of corresponding voltage values of the average breath.

function [time, voltage] = averageBreath(bellowsDataFilename)

% Set data channels
channels.time = 1;
channels.voltage = 2;
channels.xrayOn = 5;
channels.mouthPressure = 2;
channels.bloodPressure = 5;

% Set bellows sample rate in seconds
bellowsSampleRate = 0.01;

% Load breathing trace
breathTrace = importdata(bellowsDataFilename);
t = breathTrace(:, channels.time);
breathTrace = breathTrace(:,channels.voltage);

% User selects relevant range
selectionPlot = figure;
set(selectionPlot,'units','normalized','position', [0.1000    0.1000    0.8100    0.8100]);
hold on
plot(t, breathTrace,'b');
set(selectionPlot.CurrentAxes,'fontsize',20)
xlabel('Time (s)');
ylabel('Bellows Voltage (V)');
title(sprintf('Select a region of the breathing trace to average.'),'FontSize',20);
pointList = selectdata('sel','r','Verify','off','Pointer','crosshair');
hold off
close(selectionPlot);

% Use only bellows data within selected range
dataRange(1) = min(pointList);
dataRange(2) = max(pointList);

breathTrace = breathTrace(dataRange(1):dataRange(2));
t = t(dataRange(1):dataRange(2));
t = t - t(1);

%% Segment trace into individual breaths
[maxtab, mintab] = peakdet(breathTrace, .025);
peakInds = maxtab(:,1);
valleyInds = mintab(:,1);

% Plot breathing trace with peaks and valleys overlaid
tracePlot=figure;
set(tracePlot,'units','normalized','position', [0.1000    0.1000    0.8100    0.8100]);
set(tracePlot.CurrentAxes,'fontsize',20)
plot(t, breathTrace,'b')
hold on
plot(t(peakInds),breathTrace(peakInds),'ro','MarkerSize',8);
plot(t(valleyInds),breathTrace(valleyInds),'ko','MarkerSize',8);
xlabel('Time (s)', 'fontsize', 20);
ylabel('Bellows Voltage (V)', 'fontsize',20);
hold off

% Skip first and last peaks
breaths = cell(length(peakInds) - 2,1);

for i = 1:length(peakInds) - 2
breaths{i} = breathTrace(peakInds(i + 1) : peakInds(i + 2));
end

%% Discard outliers

% Set tolerance to 2 standard deviatons
tol = 2;

% Check amplitude
ampMin = cellfun(@min, breaths);
ampMax = cellfun(@max,breaths);

outlierInds = ampMin < (mean(ampMin) - tol * std(ampMin)); 
outlierInds = outlierInds + ampMax > (mean(ampMax) + tol * std(ampMax));

% Check period
period = cellfun(@length, breaths);
outlierInds = outlierInds + (period < (mean(period) - tol * std(period))) | (period > (mean(period) + tol * std(period)));

% Remove outliers in amplitude and period
breaths(logical(outlierInds)) = [];

%% Generate average breath

%breathGrid = [5:5:85]; 

% Invert the breathing signal for sanity reasons
breaths = cellfun(@(x) x * -1, breaths, 'uni',false);
% Now, inhalation is positive and exhalation is negative
[~,maxInhaleInds] = cellfun(@max, breaths,'uni',false);

% Assemble full trace with outliers removed
breathTrace = cell2mat(breaths);

% Compute 5th and 85th percentile amplitude, treat as maximum and minimum
% Make grid of amplitudes to sample at

breathGrid = linspace(prctile(breathTrace,5),prctile(breathTrace,95),25);

% Smooth each breath
breaths = cellfun(@smooth, breaths, 'uni',false);

% For each breath:
% Find the times from the beginning of the breath that the voltage
% values in breathGrid occur, treating inhalation and exhalation
% seperately.

allInhaleTimes = zeros(length(breathGrid), length(breaths));
allExhaleTimes = zeros(length(breathGrid), length(breaths));
allMaxTimes = zeros(1, length(breaths));
allMaxAmps = zeros(1, length(breaths));

for ind = 1:length(breaths)

% Interpolate bellows voltage for higher accuracy when finding times
breathT = linspace(0,length(breaths{ind}) * bellowsSampleRate,5000);
bellowT = [0:bellowsSampleRate:(length(breaths{ind}) - 1) * bellowsSampleRate];
breathV = interp1(bellowT,breaths{ind},breathT,'pchip');

% Inhale
[~, maxInhaleInd] = max(breathV); 
inhaleTimes = bsxfun(@(x,y) abs(x - y), breathV(1:maxInhaleInd)', breathGrid);
[~,inhaleTimes] = min(inhaleTimes);
inhaleTimes = breathT(inhaleTimes);

% Exhale
exhaleTimes = bsxfun(@(x,y) abs(x - y), breathV(maxInhaleInd:end)',breathGrid);
[~,exhaleTimes] = min(exhaleTimes);
exhaleTimes = exhaleTimes + maxInhaleInd - 1;
exhaleTimes = breathT(exhaleTimes);

allInhaleTimes(:,ind) = inhaleTimes';
allExhaleTimes(:,ind) = exhaleTimes';
allMaxTimes(ind) = breathT(maxInhaleInd);
allMaxAmps(ind) = breathV(maxInhaleInd);
end

% Average the times across all breaths
inhaleTimesAvg = mean(allInhaleTimes,2);
exhaleTimesAvg = mean(allExhaleTimes,2);
maxTime = mean(allMaxTimes);
maxAmp = mean(allMaxAmps);

% Flip order of exhalation values and times so that they
% can be appended to inhalation and insert peak value

avgT = [inhaleTimesAvg; maxTime; flipdim(exhaleTimesAvg,1)];
avgV = [breathGrid'; maxAmp; flipdim(breathGrid',1)];

% Remove replicate data points
[avgT, avgV, ~] = consolidator(avgT,avgV);

% Convert times to seconds and start at 0
avgT = avgT - avgT(1);
% Use cubic spline interpolaton
time = linspace(0,avgT(end),500);
voltage = interp1(avgT, avgV, time, 'spline');

% Okay, invert the voltage again 
voltage = voltage * -1;

%% Plot average breath
avgBreathFig = figure;
set(avgBreathFig.CurrentAxes, 'fontsize', 20);
set(avgBreathFig,'units','normalized','position', [0.1000    0.1000    0.8100    0.8100]);
plot(time,voltage);
xlabel('Time (s)', 'fontsize',20);
ylabel('Bellows Voltage (V)', 'fontsize', 20);
end
