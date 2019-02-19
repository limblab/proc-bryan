function [new_dat] = normalize_cyclesNaN_v3(dat,new_nsamp)

[NCYCLES] = size(dat,1);

nused = 0;
for ii = 1:NCYCLES
    ind = find(~isnan(dat(ii,:)));  % only pay attention to the data that is actually defined
    nsamp = length(ind);
    temp = dat(ii,ind(1:end));
    off = mean(temp([1 end]));
    temp2 = resample(temp-off,new_nsamp,nsamp,3)+off; % resample the data to the new number of samples    
    new_dat(ii,:) = temp2';
end

