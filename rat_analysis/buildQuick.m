function H = buildQuick(filename, varargin)

params = params_defaults();

spikedata = load_plexondata_spikes_v2(filename, params.binSize, params.sorted, params.spikeCh);
spikedata = remove_synch_spikes(spikedata); %%% the cleaned spike data is stored as spikedata.channels
%spikedata = align_plexon_spikes(spikedata,ViconSync);  % uses the info in ViconSync to modify the spike data in plexondata so the streams are aligned
spikedata.datatype = 'spike';

EMG_params.binsize = params.binSize; EMG_params.EMG_lp = 20; EMG_params.EMG_hp = 50;  EMG_params.bins = 0;
EMG_params.channels = params.EMGCh;
[emgdatabin, emgdata] = load_plexondata_EMG_v2(filename, EMG_params);
%emgdata = align_plexon_analog(emgdata,ViconSync);
emgdata = bin_plexon_EMG(emgdata, EMG_params);
emgdata.datatype = 'emg';

% Get EMG channel names
emgChannelNames = containers.Map('KeyType','double','ValueType','char');
[n,allChannelNames] = plx_adchan_names(filename);
for i = 1:length(emgdata.channel)
    emgChannelNames(emgdata.channel(i)) = deblank(allChannelNames(emgdata.channel(i),:));
end
emgdata.channelNames = emgChannelNames;

end

function params = params_defaults(varargin)

params_defaults = struct( ...
    'dir'       ,'/home/blyoder/NielsenData/',...
    'spikeCh'  ,[1:16 33:48],...
    'EMGCh'    ,49:54,...
    'binSize'   ,0.05,...
    'sorted'    ,0 ...
);

params = params_defaults;

end