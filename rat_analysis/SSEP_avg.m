clear
% File, PS/Battery, Amp, PW (not correct)
%SPIKEtargetfile = 'E1_180117_SSEP1.plx'; %PS-1/.4
%SPIKEtargetfile = 'E1_180117_SSEP2.plx'; %PS-2/.4
%SPIKEtargetfile = 'E1_180117_SSEP3.plx'; %PS-.5/.4
%SPIKEtargetfile = 'E1_180117_SSEP4.plx'; %PS-.5/.4
%SPIKEtargetfile = 'E1_180117_SSEP5.plx'; %Battery-2/.4
%SPIKEtargetfile = 'E3_180117_SSEP1.plx'; %Battery-1/.4 ?
SPIKEtargetfile = 'E3_180117_SSEP1.plx'; %Battery-4/.4
%SPIKEtargetfile = 'E3_180117_SSEP3.plx'; %Battery-.1/.4
params = 'E3, 0.5mA, 0.2ms, 1.002Hz';


fieldCh = [0:16];            % Specify the channels that contain field (LFP or EFP) recordings

%
filenames = dir(SPIKEtargetfile);
filename = strtok(filenames(1).name,'.');
filename2 = strtok(filenames(1).name);

fielddata = import_plexon_analog([pwd '/'], filename, fieldCh); %Import LFPs
[~,spikedata] = import_plexon(filename2, [0:16], [1:16]);
fielddata.timeframe = fielddata.timestamps(1) + single(0:1/fielddata.freq(1):(length(fielddata.data)-1)/fielddata.freq(1));
%ts = mytimeseries;
%ts.Data = fielddata.data'; 
%ts.Time = fielddata.timeframe;

%

alltdat = [];
dat = fielddata.data';

% dat = right_dat;
%stimind_t = find(abs(dat(:,17)) > .1); 
%stimind_t = find(dat(:,17) > .1); 

stimind_t = [];

for i = 1:length(spikedata(1).ts)
    numevents = 0;
    for j = 2:16
        numevents = numevents + ismember(spikedata(1).ts(i),spikedata(j).ts);
    end
    if numevents > 2
       stimind_t(end+1) = spikedata(1).ts(i); 
    end
end

%test
stimind_t = spikedata(1).ts;



% j=1;
% for i = 1:length(stimind_t)-1
%     if stimind_t(i+1) - stimind_t(i) > 1000
%         stimind(j) = stimind_t(i);
%         j = j+1;        
%     end    
% end

% dat = left_dat;
% stimind = find(abs(dat(:,17)) > .1); 
stimind = round(stimind_t * 2000);

%%
dt = mean(diff(fielddata.timeframe));
nstim = length(stimind)
ind1 = 500;
ind2 = 500;
temp_y1 = 0;
temp_y2 = 0;
for jj = 1:16
    subplot(4,4,jj)
    for ii = 1:nstim
        tdat = dat((stimind(ii)-ind1):(stimind(ii)+ind2),jj);
        alltdat(ii,:) = tdat;
    end
    hold on
    tind = (-ind1:ind2)/2;
    
    plot(tind,mean(alltdat),'r');
    xlabel('ms');
    ylabel('mV');
    
    a = axis;
    if jj == 1
        temp_y1 = a(3); 
        temp_y2 = a(4);
    end
    if jj == 7 || jj == 9
        axis([tind([1 end]) a(3:4)])
    else
        %axis([tind([1 end]) temp_y1, temp_y2])  
        axis([tind([1 end]) -0.015, 0.015])
    end    
end
subplot(4,4,1)
title(params)
savefig([strrep(SPIKEtargetfile,'.plx','') '_avg2.fig'])