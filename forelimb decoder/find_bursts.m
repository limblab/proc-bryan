function [onsets,offsets] = find_bursts(data,threshold,period)

% should probably make this an argument rather than setting it here
MINGAP = .05*1/period;  % mininum number of samples as a gap in a burst

% find the parts of teh data above the threshold
ind = find(data > threshold);
trace = data*0;
trace(isnan(trace)) = 0;  % this is poor, but should work
trace(ind) = 1;
ind2 = find(diff(trace) > 0);  % the breaks up
onsets = ind2+1;
ind2 = find(diff(trace) < 0);  % the breaks down
offsets = ind2;

    % make sure the first onset is before the first offset
    while (onsets(1) > offsets(1))
        offsets = offsets(2:end);
    end
    
    % make sure the last offset is after the last onset
    while (offsets(end) < onsets(end))
        onsets = onsets(1:(end-1));
    end
    
    % eliminate any cycle that has a NaN within it
    nonsets = length(onsets);
    nn = 1;
    for ii = 1:nonsets
        if (isnan(data(onsets(ii)-1)) | isnan(data(offsets(ii)+1)))
            nn = nn;
        else
            new_onsets(nn) = onsets(ii);
            new_offsets(nn) = offsets(ii);
            nn = nn+1;
        end
    end
    onsets = new_onsets;
    offsets = new_offsets;
    
    % merge any cycles separated by less than the MINGAP number of samples
    nonsets = length(onsets);
    % usecycle(1) = 1;
    ii = 2;
    while ii <= nonsets
        if (onsets(ii) - offsets(ii-1)) < MINGAP
            %         usecycle(ii) = 0;
            offsets(ii-1) = offsets(ii);
            ind = setdiff(1:nonsets,ii);
            onsets = onsets(ind);
            offsets = offsets(ind);
            nonsets = length(onsets);
        else
            %         usecycle(ii) = 1;
            ii = ii +1;
        end
    end
    % ind = find(usecycle);
    % onsets = onsets(ind);
    % offsets = offsets(ind);
