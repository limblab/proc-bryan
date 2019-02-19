function ratDecodeWrapper(filename,rat_params)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

try
    if ~exist('rat_params')
        rat_params = struct(); % set up an empty structure to pass in
    end
    
    rat_params = rat_params_defaults(rat_params);
catch ME
    %error(ME) % kick us out if necessary
end

%% Implement Vicon decoder 
% Vicon_sync = import_plexon_analog([rat_params.path '\'], rat_params.plx_file, rat_params.viconCh); %Import the Vicon synchronizing channel
% Keep only data the data when Vicon was recording:
% viconChannel = find(Vicon_sync.channel == rat_params.viconCh);
% plxVicon = Vicon_sync.data(viconChannel,:) > -1; %change back to 1 for trials with valid plexon file
% plxFreq = Vicon_sync.freq(1);
% ind = find(plxVicon);  % find the samples when Vicon is collecting data
% 
% useind = ind(1);
% if length(find(diff(plxVicon) > .5)) > 1
%     disp('maybe more than one segment of Vicon acquisition in this file')
%     plot(Vicon_sync.data)    
%     ind2 = find(diff(ind)>1);
%     indices = [1 ind2+1];
%     title(ind(indices))
%     resp = inputdlg('which index do you want?');
%     useind = ind(indices(str2num(resp{1})));
% end
% 
% ViconSync.OnsetSample = useind;  % the Plexon sample where Vicon starts  - assuming only a single period of collection in each file
% ViconSync.OnsetTime = Vicon_sync.timeframe(useind);  % the time in the Plexon file when Vicon starts
% % ViconSync.OffsetSample = ind(end);   % the sample where the Vicon stops
% % ViconSync.OffsetTime = ViconSync.OffsetSample/plxFreq;  % the time where the Vicon stops
% disp(['vicon starts ' num2str(ViconSync.OnsetTime) ' seconds in Plexon file'])
% 
% ViconSync.timeframe_plexon = Vicon_sync.timeframe;
% ViconSync.timeframe_aligned = Vicon_sync.timeframe - ViconSync.OnsetTime;  % this has the times of plexon analog signals, such that t = 0 is when Vicon starts


%% Load neural data and bin it.
spikedata = load_plexondata_spikes(filename, rat_params.binSize, rat_params.sorted);
spikedata = remove_synch_spikes(spikedata); %%% the cleaned spike data is stored as spikedata.channels
%spikedata = align_plexon_spikes(spikedata,ViconSync);  %uses the info in ViconSync to modify the spike data in plexondata so the streams are aligned
%spikedata.datatype = 'spike';
pause(1);

%% Load EMG data and bin it.
EMG_params.binsize = binSize; EMG_params.EMG_lp = 20; EMG_params.EMG_hp = 50;  EMG_params.bins = ViconSync.binedges;
EMG_params.channels = EMGCh;
[emgdatabin, emgdata] = load_plexondata_EMG_v2(filename, rat_params.EMG_params);
emgdata = align_plexon_analog(emgdata,ViconSync);
emgdata = bin_plexon_EMG(emgdata, EMG_params);
emgdata.datatype = 'emg';

% Get EMG channel names
emgChannelNames = containers.Map('KeyType','double','ValueType','char');
[n,allChannelNames] = plx_adchan_names(SPIKEtargetfile);
for i = 1:length(emgdata.channel)
    emgChannelNames(emgdata.channel(i)) = deblank(allChannelNames(emgdata.channel(i),:));
end
emgdata.channelNames = emgChannelNames;
emgdata.channelNames2 = EMGCh_labels;
emgdata.params = EMG_params;

end

