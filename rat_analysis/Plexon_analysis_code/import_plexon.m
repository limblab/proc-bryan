%analog channels go from 0-63, spike channels go from 1-64
function [an_data, spike_data] = import_plexon(filename, an_ch, spike_ch)

%set flag if manually entered channels, otherwise, grab all channels with
%data
ch_flag = 1;
if nargin == 3
    ch_flag = 0;
end
    
%set up the analog data structure
an_data = struct(); 
an_data.ch = []; %array of channel numbers
an_data.ts = []; %time stamps
an_data.data = []; %a/d values for those channels
an_data.freq = []; %save frequency of channels

%set up spike data structure
spike_data = struct();
spike_data.ch = [];
spike_data.ts = [];

if ch_flag == 1  %find which channels have data
    %get channels with more than 0 data points recorded for spikes and
    %analog
    [~, map] = plx_ad_chanmap(filename);
    [ts_count,~,~,count] = plx_info(filename,1);
    an_ch = map(find(count));
    spike_ch = find(ts_count(1,:)) - 1;
end    

for channel = an_ch
    %import data
    [adfreq, ~, ts, ~, ad] = plx_ad_v([filename], channel);
    %if there is data on a channel, add it to the data structure
    if ad~=-1
        if ch_flag == 1
            disp(['channel ' num2str(channel) ' has actual values so save them'])
        end
        an_data.data(:, end+1) = ad; 
        an_data.ts(end+1) = ts; 
        an_data.ch(end+1) = channel; 
        an_data.freq(end+1) = adfreq; 
        %figure; plot(ad, '.-')
    end 
end

for i = 1:length(spike_ch)
    [n, ts] = plx_ts(filename, spike_ch(i), 0); 
    %if there is data on a channel, add it to the data structure
    if ts~=-1
        if ch_flag == 1
            disp(['channel ' num2str(spike_ch(i)) ' has actual values so save them'])
        end
        spike_data(i).ts = ts;
        spike_data(i).fr = histc(spike_data(i).ts,0:0.01:length(an_data.data(:,1))/an_data.freq(1)); %spike_data(i).fr(end) = [];
        [spike_data(i).sfr] = smooth_gaussian(spike_data(i).fr,5);
        spike_data(i).ch = spike_ch(i);
    end
end

an_data.data = an_data.data'; %We want the data in a CHANNELS x TIMESTAMPS format

% if exist([data_dir 'mat_files/'], 'dir') ~= 7 %If mat_files folder doesn't exist:
%     mkdir ([data_dir 'mat_files/']);
% end
% %now save the Epidural data as a .mat file in the mat_files folder
% save([data_dir 'mat_files/' filename], 'an_data'); 

