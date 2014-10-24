%% averageBreath: calculate an average breath based on a graphically specified region
% of the patient's breathing trace.  The average breath can then be sampled for 
% (v,f) phases to generate images at using generate5DCT
%
% usage: [breathAmp, t] = averageBreath(bellowsDataFilename)
% 
% dependencies: selectdata, consolidator
%
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
breathGrid = [5:5:95]; 

% Invert the breathing signal for sanity reasons
breaths = cellfun(@(x) x * -1, breaths, 'uni',false);
% Now, inhalation is positive and exhalation is negative

% Inhalation
[~,maxInhaleInds] = cellfun(@max, breaths,'uni',false);
inhalePercs = cellfun(@(x,y) prctile(x(1:y),breathGrid), breaths, maxInhaleInds, 'uni',false);
inhaleTimes = cellfun(@(x,y,z) bsxfun(@(q,r) abs(q - r), x(1:y), z), breaths, maxInhaleInds, inhalePercs, 'uni',false);
[~,inhaleTimes] = cellfun(@min,inhaleTimes,'uni',false);

% Conversion from cell to matrix -- why not?
inhalePercs = cell2mat(inhalePercs);
inhaleTimes = cell2mat(inhaleTimes);

% Calculate the average voltage and time of each percentile in breathGrid
inhalePercAvg = mean(inhalePercs,1);
inhaleTimeAvg = mean(inhaleTimes,1);


% Exhalation
exhalePercs = cellfun(@(x,y) prctile(x(y:end),breathGrid), breaths, maxInhaleInds,'uni',false);
exhaleTimes = cellfun(@(x,y,z) bsxfun(@(q,r) abs(q - r), x(y:end), z), breaths, maxInhaleInds, exhalePercs, 'uni',false);
[~,exhaleTimes] = cellfun(@min,exhaleTimes,'uni',false);
% Shift exhalation times
exhaleTimes = cellfun(@(x,y) x + y, exhaleTimes, maxInhaleInds, 'uni', false);

% Conversion from cell to matrix -- why not?
exhalePercs = cell2mat(exhalePercs);
exhaleTimes = cell2mat(exhaleTimes);

% Calculate the average voltage and time of each percentile in breathGrid.
% Flip the order so that it can be appended to the inhalation
exhalePercAvg = flipdim(mean(exhalePercs,1),2);
exhaleTimeAvg = flipdim(mean(exhaleTimes,1),2);

avgT = [inhaleTimeAvg exhaleTimeAvg];
avgV = [inhalePercAvg exhalePercAvg];

% Remove replicate data points
[avgT, avgV, ~] = consolidator(avgT,avgV);

% Convert times to seconds
avgT = avgT * bellowsSampleRate;

% Use cubic spline interpolaton
time = linspace(min(avgT),max(avgT),500);
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
