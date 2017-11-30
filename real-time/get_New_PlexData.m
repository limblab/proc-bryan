function new_spikes = get_New_PlexData(s, params)

new_spikes = zeros(length(params.n_neurons),1);
% get data
[n, ts_new] = PL_GetTS(s);

% check if data makes sense

% If it covers too much time
if ts_new(end,4) - ts_new(1,4) >= 0.06
   warning('Recieved spikes exceed bin time; interval: %f',ts_new(end,4) - ts_new(1,4))    
end

% remove stim artifacts
ts_array = remove_Artifacts(ts_array, params);


for i = params.neuronIDs
    if i(2) % Get multi-unit activity
        new_spikes(params.neuronIDs(:,1) == i) = length(find(i == ts_array(:,2)))/params.binsize;
    else    % Get individual units
        
    end
end


% firing_rates = [new_spikes'; data.spikes(1:end-1,:)];

% remove any high frequency noise
if any(new_spikes > 400)
    new_spikes(new_spikes>400) = 400;
    warning('Noise detected, FR capped at 400 Hz');
end