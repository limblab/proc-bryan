function [allstepdata, arrdata, phasesind] = extract_stepdata(data,datatimes,cycletimes);

nind = size(cycletimes,2);  % the number of columns
if nind == 2  % they only sent in starts and stops
    cycletimes2(:,1:3) = cycletimes;
    cycletimes2(:,2) = mean(cycletimes);  % make the middle point just halfway in between
elseif nind == 3  % they sent in a midpoint (stance/swing transition)
    cycletimes2 = cycletimes;
end

maxnsamp = 0;
allstepdata = [];  % this will store the step data
nsamp = length(datatimes);
usedind = zeros(nsamp,1);  % this will contain a flag saying which parts of the original data were actually extracted for steps
phasesind = zeros(nsamp,2); 
ncycles = size(cycletimes2,1);
for ii = 1:ncycles
    usetimes = [cycletimes2(ii,1) cycletimes2(ii,3)]; % these are the start/stop times for this step
    ind = find((datatimes >= usetimes(1)) & (datatimes <= usetimes(2))); % the indices into the data with these times
    usedind(ind) = 1;  % flag these as being used for step data
    steptimes = datatimes(ind); % these are the times in the data
    stepdata = data(ind,:);  % this is the data for this step
    swingind = find(steptimes <= cycletimes2(ii,2));  % find the transition point in the step
    if length(swingind) > 0
        stanceind = (swingind(end)+1):length(steptimes);  % the second phase
    else
        stanceind = find(steptimes <= cycletimes2(ii,3));
    end
    CLASSdat = []; CLASSdat(swingind) = 0; CLASSdat(stanceind) = 1; % this has the step definition

    phasesind(ind(swingind),1) = 1;  % flag these as being used for step data
    phasesind(ind(stanceind),2) = 1;  % flag these as being used for step data

    stepdata(:,end+1) = CLASSdat;  % add this info to the step data
    allstepdata{ii} = stepdata; % each step
    nsamp = length(ind);
    maxnsamp = max(maxnsamp,nsamp);
end

nchan = size(allstepdata{1},2);
arrdata = NaN*zeros(ncycles,nchan,maxnsamp);
for ii = 1:ncycles
    nsamp = size(allstepdata{ii},1);
    arrdata(ii,:,1:nsamp) = allstepdata{ii}';
end

