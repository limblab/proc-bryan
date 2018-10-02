filename = 'N19_180831_flexor.plx';
EMGChans = [48:54];

stimFreq = 25;
numPulses = 5;

data = [];
for i = EMGChans

    [freq,n,ts,~,ad] = plx_ad_v(filename,i);
    data(:,end+1) = ad;
    
end
ts = 0:1/freq:((n-1)/freq);


dist = freq/stimFreq;
potStim = []; %potential stim points
i = 6;

for j = 100:length(data(:,i))-100
    if data(j,i) > .2 && data(j+1,i) < -.2 && std(data([j-50:j-1 j+2:j+50],i))<.05
        potStim(end+1) = j;
    end
end

%% Plot Stuff
numSec = 3;
for i = 1:length(realStim)
    figure(i)
    ax1 = subplot(7,1,1)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,1))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,1));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax1,'TA')
    ax2 = subplot(7,1,2)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,2))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,2));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax2,'LG')
    ax3 = subplot(7,1,3)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,3))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,3));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax3,'BFp')
    ax4 = subplot(7,1,4)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,4))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,4));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax4,'BFa')
    ax5 = subplot(7,1,5)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,5))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,5));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax5,'LG')
    ax6 = subplot(7,1,6)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,6))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,6));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax6,'GS')
    ax7 = subplot(7,1,7)
    plot(-1:1/freq:numSec,data(realStim(i)-freq:realStim(i)+freq*numSec,7))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,7));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax7,'IP')
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7],'x');
end

avestim = data(realStim(1)-freq:realStim(1)+freq*numSec,:);
for i = 2:length(realStim) 
    avestim = avestim + data(realStim(i)-freq:realStim(i)+freq*numSec,:);
end
avestim = avestim/7;


%% bin and filter EMGs
binsize = 0.05;
EMG_hp = 10;
EMG_lp = 50;
NormData = 0;

%timeframe will be the binned times
% numberbins = floor((emg_times(end)-emg_times(1))/params.binsize);
% timeframe = ones(numberbins,1);
timeframe = (0:binsize:ts(end)-binsize)';
numberbins = length(timeframe);

numEMGs = size(data,2);
emgtimebins = 1:length(data(:,1));

%Pre-allocate matrix for binned EMG 
emgdatabin = zeros(numberbins,numEMGs);

% Filter EMG data: [B,A] = butter(N,Wn,'high'), N = order(#poles), Wn = 0.0 < Wn < 1.0, with 1.0 corresponding to half the sample rate.
[bh,ah] = butter(3, EMG_hp*2/freq, 'high'); %highpass filter params
[bl,al] = butter(3, EMG_lp*2/freq, 'low');  %lowpass filter params

for E=1:numEMGs
    % Filter EMG data
    tempEMG = double(data(emgtimebins,E));
    %figure; plot(tempEMG)           
    tempEMG = filtfilt(bh,ah,tempEMG); %highpass filter
    %figure; plot(tempEMG)
    tempEMG = abs(tempEMG); %rectify
    %figure; plot(tempEMG)
    tempEMG = filtfilt(bl,al,tempEMG); %lowpass filter
    %figure; plot(tempEMG)
    %end
    %downsample EMG data to desired bin size
%             emgdatabin(:,E) = resample(tempEMG, 1/binsize, emgsamplerate);
    emgdatabin(:,E) = interp1(emgtimebins/freq, tempEMG, timeframe,'linear','extrap');
end

%Normalize EMGs        
if NormData
    for i=1:numEMGs
%             emgdatabin(:,i) = emgdatabin(:,i)/max(emgdatabin(:,i));
        %dont use the max because of artefact, use 99% percentile
        EMGNormRatio = prctile(emgdatabin(:,i),99);
        emgdatabin(:,i) = emgdatabin(:,i)/EMGNormRatio;
    end
    emgdatabin(emgdatabin>1) = 1; % set everything greater than 1 to 1
end

%% plot binned EMGs
realStimBin = floor(realStim/freq/binsize);
numSec = 4;
for i = 1:length(realStim)
    figure(i)
    ax1 = subplot(7,1,1)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,1))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,1));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax1,'TA')
    ax2 = subplot(7,1,2)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,2))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,2));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax2,'LG')
    ax3 = subplot(7,1,3)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,3))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,3));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax3,'BFp')
    ax4 = subplot(7,1,4)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,4))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,4));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax4,'BFa')
    ax5 = subplot(7,1,5)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,5))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,5));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax5,'LG')
    ax6 = subplot(7,1,6)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,6))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,6));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax6,'GS')
    ax7 = subplot(7,1,7)
    plot(-1:binsize:numSec,emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,7))
    %y = max(data(realStim(i):realStim(i)+freq*numSec,7));
    %line([realStim(i)/freq realStim(i)/freq], [1.5*y -1.5*y],'Color','Red')
    title(ax7,'IP')
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7],'x');
end

%Average binned data
avestim = emgdatabin(realStimBin(2)-1/binsize:realStimBin(2)+numSec/binsize,:);
for i = 3:4 
    avestim = avestim + emgdatabin(realStimBin(i)-1/binsize:realStimBin(i)+numSec/binsize,:);
end
avestim = avestim/3;

figure(1)
ax1 = subplot(7,1,1)
plot(-1:binsize:numSec,avestim(:,1))
title(ax1,'TA')
ax2 = subplot(7,1,2)
plot(-1:binsize:numSec,avestim(:,2))
title(ax2,'LG')
ax3 = subplot(7,1,3)
plot(-1:binsize:numSec,avestim(:,3))
title(ax3,'BFp')
ax4 = subplot(7,1,4)
plot(-1:binsize:numSec,avestim(:,4))
title(ax4,'BFa')
ax5 = subplot(7,1,5)
plot(-1:binsize:numSec,avestim(:,5))
title(ax5,'LG')
ax6 = subplot(7,1,6)
plot(-1:binsize:numSec,avestim(:,6))
title(ax6,'GS')
ax7 = subplot(7,1,7)
plot(-1:binsize:numSec,avestim(:,7))
title(ax7,'IP')
linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7],'x');