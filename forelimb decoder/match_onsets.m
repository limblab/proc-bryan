function finalonsets = match_onsets(onsets,onsets1,MAXNSAMP)

nons = length(onsets(:,1));
nn = 1;
ind = 0;
finalonsets = [0 0 0];
for ii = 1:nons
    useind = (ind+1):length(onsets1(:,1));
    diffs = (onsets(ii,1)-onsets1(useind,1)); % find the distance to each candidate onset
    ind2 = find(diffs > 0); % these are the ones that come before - ignore
    diffs(ind2) = 9999;
    [mn,ind] = min(abs(diffs));  % find the nearest one after the current onset
    if mn < MAXNSAMP  % make sure that the distance is less than the max cycle duration 
        finalonsets(nn,:) = [onsets(ii,1) onsets1(useind(ind(1)),1) onsets(ii,2)];
        nn = nn+1;
    end
end
