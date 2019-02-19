%%  find the data to use to define cycles - use data at high sampling rate, not binned
DISPLAY = 1;

[KINdat, KINtimes] = get_CHN_data(kinematicData,'raw');
useind = find((KINtimes<14500) & (KINtimes > 1));  % limit the span of data that willbe used

% % N30
% temp = kinematicData.refKinMatrix(useind,22) - kinematicData.refKinMatrix(useind,28);  % this is in case the kinematics aren't already zeroed to the shoulder/hip
temp = kinematicData.refKinMatrix(useind,13) - kinematicData.refKinMatrix(useind,4);  % this is in case the kinematics aren't already zeroed to the shoulder/hip

% N8, N19
% temp = kinematicData.refKinMatrix(useind,7) - kinematicData.refKinMatrix(useind,1);  % this is in case the kinematics aren't already zeroed to the shoulder/hip

temp2 = inpaint_nans(temp);  % deal with the NaN, using Pablo's function
%  temp12 = inpaint_nans(temp1);  % deal with the NaN, using Pablo's function
usetimes = KINtimes(useind);

%% This is the actual processing to find the step times
FREQ = kinematicData.freq;  % the sampling frequency
THRESH = .01;  % this is the threshold touseforthe
MINNSAMP = 10;  MAXNSAMP = 200; % these are the numbers to use for the mininum and maximum step length
MINPHASEDUR = 3;

[b,a] = butter(2,.25/(FREQ/2),'high');
temp3 = filtfilt(b,a,temp2);   % high pass filter the stepping to get rid of drifts

[ons,offs] = find_bursts(-temp3,THRESH*max(temp3),1);  % find windowsthat contain the maxima of the trace
[ons1,offs1] = find_bursts(temp3,THRESH*max(-temp3),1);  % find windowsthat contain the minima of the trace

% now find the maxima within each of those windows,rejects any cycles that are too short or too long
onsets = get_cycle_onsets_from_ided_times(-temp3,[ons; offs]',[MINNSAMP MAXNSAMP]); 
onsets1 = get_cycle_onsets_from_ided_times(temp3,[ons1; offs1]',[MINNSAMP MAXNSAMP]); 

% find matched onsets, to find stance vs. swing phases
finalonsets = match_cycle_times(onsets,onsets1,MAXNSAMP,MINPHASEDUR);
finalcycletimes = usetimes(finalonsets);  % put these onset indices into times

if DISPLAY
    plot(usetimes,temp3)
    hold on
    plot(finalcycletimes(:,1),temp3(finalonsets(:,1)),'ro')
    plot(finalcycletimes(:,2),temp3(finalonsets(:,2)),'bo')
    plot(finalcycletimes(:,3),temp3(finalonsets(:,3)),'gx')
    hold off
end

%%  now extract data according to the times for each step
[APdat, APtimes] = get_CHN_data(spikedata,'binned',KINtimes);
[allstepdata, arrdatakin, usedind] = extract_stepdata(temp3,usetimes,finalcycletimes);
ind = find(APtimes > usetimes(1));
[allstepdata, arrdata, usedind] = extract_stepdata(APdat(ind,:),APtimes(ind),finalcycletimes);
outputdata = usedind;
inputdata = APdat(ind,1:31);
outputtimes = APtimes(ind)';

%% now normalize each of the extracted cycles
N_NORMSAMP = 100;  % the new number of samples to have in the mean

% the spike data
[ncycles,nchan,maxnsamp] = size(arrdata);  % the number of data channels
arrdata2 = zeros(ncycles,nchan,N_NORMSAMP);
for ii = 1:nchan
    new_dat = normalize_cyclesNaN_v3(squeeze(arrdata(:,ii,:)),N_NORMSAMP);
    arrdata2(:,ii,:) = new_dat;
end

% the kinematic data
[ncycles,nchan,maxnsamp] = size(arrdatakin);  % the number of data channels
arrdatakin2 = zeros(ncycles,nchan,N_NORMSAMP);
for ii = 1:nchan
    new_dat = normalize_cyclesNaN_v3(squeeze(arrdatakin(:,ii,:)),N_NORMSAMP);
    arrdatakin2(:,ii,:) = new_dat;
end
   
if DISPLAY
    temp = squeeze(mean(arrdata2,1));  % average across cycles
    mn = min(temp');
    temp2 = temp - repmat(mn',1,N_NORMSAMP);
    mx = max(temp2');
%     temp2 = temp2./repmat(mx',1,N_NORMSAMP);
%     chanlist = [1:7 9:23 25:33];
nchan = size(temp,1);
chanlist = setdiff([1 3:32],25);
    imagesc(temp2(chanlist,:))
    colorbar
end

%%

ind = 7500:7600;
mx = max(inputdata(ind,:)');
imagesc(inputdata(ind,:)')
figure
plot(outputdata(ind,2))

