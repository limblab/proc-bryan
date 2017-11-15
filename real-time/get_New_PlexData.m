function [new_spikes, ts_old] = get_New_PlexData(s, ts_old, params)

new_spikes = zeros(length(params.spike_channels),1);
%get data
[n, ts_new] = PL_GetTS(s);
%Add ts that weren't binned last time
if n
    ts_array = [ts_old; ts_new];
else
    ts_array = ts_old;
end

%Remove ts that are too late
index = min(find(ts_array(:,4) > ***value))
if ~isempty(index)    
    ts_array = ts_array(1:index-1,:);
    ts_old = ts_array(index:end,:);
else
    ts_old = [];
end
%remove stim artifacts
ts_array = remove_Artifacts(ts_array, params);


for i = params.spike_channels
    new_spikes(params.spike_channels == i) = length(find(i == ts_array(:,2)));    
end

%firing_rates = [new_spikes'; data.spikes(1:end-1,:)];

end