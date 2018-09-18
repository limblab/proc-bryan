function [emgdatabin, emg_data] = load_plexondata_EMG_v2(filename, params)

emg_channels = params.channels;    %I think this is really just 48:64 but I'm hedging my bets
emgdatabin = [];

%set up the EMG data structure
emg_data = struct(); 
emg_data.channel = []; %array of channel numbers
emg_data.timestamps = []; %time stamps
emg_data.data = []; %a/d values for those channels
emg_data.freq = [];

for channel = emg_channels 
    %import data
    [adfreq, ~, ts, ~, ad] = plx_ad_v([filename], channel);
    %if there is data on a channel, add it to the data structure
    if ad~=-1
        disp(['channel ' num2str(channel) ' has actual values so save them'])
        emg_data.data(:, end+1) = ad; 
        emg_data.timestamps(end+1) = ts; 
        emg_data.channel(end+1) = channel; 
        emg_data.freq = adfreq; %It will be overwritten, but all channels will have been collected at same freq
    
    else
    disp(['channel ' num2str(channel) ' has no EMG values'])    
    end
end

if ~isempty(emg_data.channel)    
    emgsamplerate = emg_data.freq;   %Rate at which emg data were actually acquired.
    emg_times = emg_data.timestamps(1) + single(0:1/emgsamplerate:(size(emg_data.data,1)-1)/emgsamplerate);
    emg_data.timeframe = emg_times;
    
%     try
%         emgdatabin = bin_plexon_EMG(emg_data, params);
%     catch
%         emgdatabin = [];
%         warning('Could not bin EMGs');
%         return;
%     end
else
    fprintf('No EMG data was found\n');       
    
end
