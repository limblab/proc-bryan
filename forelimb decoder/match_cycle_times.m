function finalonsets = match_cycle_times(onsets1,onsets2,MAXNSAMP,MINPHASEDUR)
%function finalonsets = match_cycle_times(onsets1,onsets2,MAXNSAMP,MINPHASEDUR)
%  Function to match step times to one another. ONSETS1 and ONSETS2
%  contain indices defining step events. This function uses the indices
%  identified in ONSETS1 to go through the events in ONSETS2 and find
%  events that happen in the same step. Only events within MXNSAMP are
%  allowed.  It returns FINALONSETS which is NSTEP X3. The first column has
%  the index of the start of the step, the 3rd column has the index of the
%  end of the step (both of these are taken from ONSETS1), and the 2nd column has the index of the event from
%  ONSETS2.

nons = length(onsets1(:,1));
nn = 1;
ind = 0;
finalonsets = [0 0 0];
for ii = 1:nons
    useind = (ind+1):length(onsets2(:,1));
    diffs = (onsets1(ii,1)-onsets2(useind,1)); % find the distance to each candidate onset
    ind2 = find(diffs > 0); % these are the ones that come before - ignore
    diffs(ind2) = 9999;
    [mn,ind] = min(abs(diffs)); % find the nearest one
    if mn < MAXNSAMP  % make sure that the distance is less than the max cycle duration 
        dphase2 = abs((onsets2(useind(ind(1)),1) - onsets1(ii,2)));  
        dphase1 = abs((onsets2(useind(ind(1)),1) - onsets1(ii,1)));
        if ((dphase1 > MINPHASEDUR) & (dphase2 > MINPHASEDUR)) % make sure this event is within the defined step        
            finalonsets(nn,:) = [onsets1(ii,1) onsets2(useind(ind(1)),1) onsets1(ii,2)];
            nn = nn+1;
        end
    end
end

