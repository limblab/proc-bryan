clear all;
close all; clc;
%% Configuration parameters

SPIKEtargetfile = 'N31_190104_nostim.plx';        % !Different from original file if sorted
filenameKin = '19-01-04_nostim.csv';              

spikeCh = 1:48;  
viconCh = 16;   % this has the TTL signal indicating when Vicon is acquiring data
sorted = 0; % Change to 1 if you're using sorted.plx file, if unsorted, set to 0 - not sure what this is doing
EMGCh_labels = {'GND','TA', 'LG', 'BFp', 'Bfa', 'VL', 'GS','IP'};

% Vicon parameters
viconScalingFactor = 4.7243;    % Factor to convert Vicon kinematics to mm.% this is now in the file reading - should be updated
viconFreq = 200;                % Frequency (Hz) at which kinematic data is acquired. Necessary to bin data. EXTRACT THIS FROM THE XLS FILE IF POSSIBLE
referenceMarker = 'shoulder';   % Marker of reference. Make center of coordinates. TIP: Use stable marker -> hip_middle. Leave empty otherwise.
binSize = 0.05;    
labels = {'stance_phase'};

%Step phase parameters
DISPLAY = 1;
FREQ = 200;  % the sampling frequency
THRESH = .01;  % this is the threshold to use for the
MINNSAMP = 10;  MAXNSAMP = 400; % these are the numbers to use for the mininum and maximum step length
MINPHASEDUR = 3;

%% Find the offset between the Vicon and the Plexon acquisition files

filenames = dir(SPIKEtargetfile);
filename = strtok(filenames(1).name,'.');  % get rid of the extension for the next file    
Vicon_sync = import_plexon_analog([pwd '/'], filename, viconCh); %Import the Vicon synchronizing channel

% Keep only data the data when Vicon was recording:
viconChannel = find(Vicon_sync.channel == viconCh);

plxVicon = Vicon_sync.data(viconChannel,:) > 1; %use 1 for valid vicon files


plxFreq = Vicon_sync.freq(1);
ind = find(plxVicon);  % find the samples when Vicon is collecting data

useind = ind(1);
if length(find(diff(plxVicon) > .5)) > 1
    disp('maybe more than one segment of Vicon acquisition in this file')
    plot(Vicon_sync.data)    
    ind2 = find(diff(ind)>1);
    indices = [1 ind2+1];
    title(ind(indices))
    resp = inputdlg('which index do you want?');
    useind = ind(indices(str2num(resp{1})));
end

ViconSync.OnsetSample = useind;  % the Plexon sample where Vicon starts  - assuming only a single period of collection in each file
Vicon_sync = add_timeframe(Vicon_sync);
ViconSync.OnsetTime = Vicon_sync.timeframe(useind);  % the time in the Plexon file when Vicon starts
% ViconSync.OffsetSample = ind(end);   % the sample where the Vicon stops
% ViconSync.OffsetTime = ViconSync.OffsetSample/plxFreq;  % the time where the Vicon stops
disp(['vicon starts ' num2str(ViconSync.OnsetTime) ' seconds in Plexon file'])

ViconSync.timeframe_plexon = Vicon_sync.timeframe;
ViconSync.timeframe_aligned = Vicon_sync.timeframe - ViconSync.OnsetTime;  % this has the times of plexon analog signals, such that t = 0 is when Vicon starts

%% define bins in Plexon time

mintime = ViconSync.timeframe_aligned(1)-binSize;
maxtime = ViconSync.timeframe_aligned(end) + 2*binSize;

part1 = -(0:binSize:(-mintime));  % these are the bins to the left of zero
part1 = fliplr(part1);

part2 = binSize:binSize:maxtime;  %these are the bins to the right
ViconSync.binedges = [part1 part2];

%% Read in the spike data and bin their rates

filenames = dir(SPIKEtargetfile);
fileind = 1;  % vestigial?
filename = filenames(fileind).name;

%Load neural data and bin it.
spikedata = load_plexondata_spikes(filename, binSize, sorted);
spikedata = remove_synch_spikes(spikedata); %%% the cleaned spike data is stored as spikedata.channels
spikedata = align_plexon_spikes(spikedata,ViconSync);  %uses the info in ViconSync to modify the spike data in plexondata so the streams are aligned
spikedata.datatype = 'spike';

%%  Read in kinematic data, express relative to reference marker, and bin them

kinematicData = importVicon([filenameKin]);  %Import kinematics

Kinparams.viconScalingFactor = viconScalingFactor; Kinparams.referenceMarker = referenceMarker; Kinparams.ViconFreq = kinematicData.freq;
kinematicData = zero_kinematic_data(kinematicData,Kinparams);

temp = kinematicData.timeframe;
ind = find((ViconSync.binedges >= temp(1)) & (ViconSync.binedges <= temp(end)));
ind = [ind(1)-1 ind];

viconbinedges = ViconSync.binedges(ind);
%kinematicData = bin_kinematic_data(kinematicData,viconbinedges); 
kinematicData.datatype = 'kinematic';

%%  find the data to use to define cycles - use data at high sampling rate, not binned

[KINdat, KINtimes] = get_CHN_data(kinematicData,'raw');
useind = find((KINtimes<14500) & (KINtimes > 0));  % limit the span of data that willbe used

% % N30
temp = kinematicData.refKinMatrix(useind,22) - kinematicData.refKinMatrix(useind,25);  % this is in case the kinematics aren't already zeroed to the shoulder/hip

% % N31
% temp = kinematicData.refKinMatrix(useind,16) - kinematicData.refKinMatrix(useind,22);  % this is in case the kinematics aren't already zeroed to the shoulder/hip


% N8, N19
% temp = kinematicData.refKinMatrix(useind,7) - kinematicData.refKinMatrix(useind,1);  % this is in case the kinematics aren't already zeroed to the shoulder/hip

temp2 = inpaint_nans(temp);  % deal with the NaN, using Pablo's function
%  temp12 = inpaint_nans(temp1);  % deal with the NaN, using Pablo's function
usetimes = KINtimes(useind);

%% This is the actual processing to find the step times
[b,a] = butter(2,.25/(FREQ/2),'high');
temp3 = filtfilt(b,a,temp2);   % high pass filter the stepping to get rid of drifts

[ons,offs] = find_bursts(-temp3,THRESH*max(temp3),1);  % find windowsthat contain the maxima of the trace
[ons1,offs1] = find_bursts(temp3,THRESH*max(-temp3),1);  % find windowsthat contain the minima of the trace

% now find the maxima within each of those windows,rejects any cycles that are too short or too long
onsets = get_cycle_onsets_from_ided_times(-temp3,[ons; offs]',[MINNSAMP MAXNSAMP]); 
onsets1 = get_cycle_onsets_from_ided_times(temp3,[ons1; offs1]',[MINNSAMP MAXNSAMP]); 

% find matched onsets, to find stance vs. swing phases
finalonsets = match_cycle_times(onsets,onsets1,MAXNSAMP,MINPHASEDUR);
finalcycletimes = usetimes(finalonsets);  % put these onset indices into times

if DISPLAY
    plot(usetimes,temp3)
    hold on
    plot(finalcycletimes(:,1),temp3(finalonsets(:,1)),'ro')
    plot(finalcycletimes(:,2),temp3(finalonsets(:,2)),'bo')
    plot(finalcycletimes(:,3),temp3(finalonsets(:,3)),'gx')
    hold off
end

%%  now extract data according to the times for each step
[APdat, APtimes] = get_CHN_data(spikedata,'binned',KINtimes);
[allstepdata, arrdatakin, usedind] = extract_stepdata(temp3,usetimes,finalcycletimes);
ind = find(APtimes > usetimes(1));
[allstepdata, arrdata, usedind] = extract_stepdata(APdat(ind,:),APtimes(ind),finalcycletimes);
outputdata = usedind;
inputdata = APdat(ind,1:32);
outputtimes = APtimes(ind)';

%outputdata = outputdata(:,2)*.5+outputdata(:,1);   %stance-0.5,swing-1
outputdata = outputdata(:,1)*.5+outputdata(:,2);   %swing-0.5,stance-1
%outputdata = 0.5-outputdata(:,1)*.5+outputdata(:,2)*.5;   %swing-1,stance-0


%% do the decoding
duration = outputtimes(end)-outputtimes(1);
binnedData = [];
ninputs = size(inputdata, 2);   % the number of channels in the input

% Set decoding parameters and predict kinematics

% Mandatory fields to specify the signal to decode 
DecoderOptions.PredEMGs = 0;             % Predict EMGs (bool)
DecoderOptions.PredCursPos = 1;          % Predict kinematic data (bool)

DecoderOptions.PolynomialOrder = 1;      % Order of Wiener cascade - 0 1 for linear
DecoderOptions.foldlength = 30;          % Duration of folds (seconds)
DecoderOptions.fillen = 0.5;             % Filter Length: Spike Rate history used to predict a given data point (in seconds). Usually 500ms.
DecoderOptions.UseAllInputs = 1;

% These parameters are standard in the LAB when using the Wiener decoder code:
binnedData.spikeratedata = inputdata;
binnedData.neuronIDs = [ [1:ninputs]' zeros(ninputs, 1)];
binnedData.cursorposbin = outputdata; %DECODING SIGNAL
binnedData.cursorposlabels = labels;
binnedData.timeframe = outputtimes;

%[PredSignal] = epidural_mfxval_decoding(binnedData, DecoderOptions);
[model,PredSignal] = BuildModel(binnedData, DecoderOptions);

PredSignal.predphase = max(min(1,round(2*PredSignal.preddatabin)/2),0);
vaf = 1 - nansum( (PredSignal.predphase-PredSignal.actualData).^2 ) ./ nansum( (PredSignal.actualData - repmat(nanmean(PredSignal.actualData),size(PredSignal.actualData,1),1)).^2 );

figure(4)
hold on
plot(PredSignal.timeframe,PredSignal.preddatabin);
plot(outputtimes,outputdata);
hold off

%% Stats on decoder performance

%number of correctly predicted phases
correctPred = PredSignal.predphase == PredSignal.actualData;
sum(correctPred)/length(correctPred)
