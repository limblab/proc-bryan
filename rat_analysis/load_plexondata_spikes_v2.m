function [plexondata] = load_plexondata_spikes_v2(filename, binSize, sorted, channels)
%
%   Changed so that it only reads in the data, doesn't do any binning to
%   find spike rates.
%

% sorted =  0 (unsorted) - 1 (sorted)
%filename = [animal '_' date '_sortedonly.plx'];

% Time information: recording length and bins for calculating firing rates
[~,~,~,~,~,~,~,~,~,~,~,plexondata.recording_length_sec,~] = plx_information(filename);

plexondata.binneddata.binwidth       = binSize;
plexondata.binneddata.timebinedges   = 0:plexondata.binneddata.binwidth:plexondata.recording_length_sec;
plexondata.binneddata.timeframe = 0.5*plexondata.binneddata.binwidth + plexondata.binneddata.timebinedges(1:end-1);

[spikecountmatrix, ~] = plx_info(filename, 1);

% Get cluster data
for channel = channels
    numclusters = length(find(spikecountmatrix(sorted+1:end,channel+1)>0)); %If the file is sorted, sorted units are saved from the 2nd raw downwards. If it is unsorted, units are on first raw.
    %[channel numclusters]
    if numclusters > 0
            clusters = struct();
            for cluster = 1:numclusters
                numspikes = spikecountmatrix(sorted+1,channel+1); % From what I saw, spikes are stored in row 1 for raw data, and in raw 2 for sorted spikes. Why?
                [~, clusters(cluster).spiketimes]    = plx_ts(filename, channel, sorted);
%                 spikehist = histc(clusters(cluster).spiketimes,plexondata.binneddata.timebinedges); spikehist(end) = [];
%                 clusters(cluster).binneddata.spikeratedata = spikehist/plexondata.binneddata.binwidth;
            end
            plexondata.channels(channel).clusters = clusters;
    end
end
