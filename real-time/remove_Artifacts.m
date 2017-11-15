function clean_ts = remove_Artifacts(spikes, params)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%Params for artifact removal
max_nbr_spikes         = 10;
reject_bin_size     = 0.001;

%Matrix is ordered by ts, independent of channel
%Roll over list with window size 'reject_bin_size' looking for at least
% 'max_nbr_spikes'
artifacts = [];

for i = 1:length(spikes)
    %Check if artifact already was recorded
    if ismember(i,artifacts)
        continue; 
    end    
    
    %check how many spikes occur in 'bin_size'
    num_events = length(find(spikes(i:end,4)-spikes(i,4) < reject_bin_size));
    if num_events >= max_nbr_spikes
        artifacts = [artifacts; [i:i+num_events-1]'];
    end
end

%Get rid of ts that are artifact
for i = 1:length(artifacts)
    spikes(artifacts) = [];    
end

%Artifacts output
if params.debug > 0 && length(artifacts) > 0
    disp([num2str(length(artifacts)) ' artifacts in bin'])    
end

clean_ts = spikes;