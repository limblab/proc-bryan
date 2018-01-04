clear
% File, PS/Battery, Amp, PW
%SPIKEtargetfile = '171218_E2_SSEP1.plx'; %PS-1/.4
SPIKEtargetfile = '171218_E2_SSEP2.plx'; %PS-2/.4
%SPIKEtargetfile = '171218_E2_SSEP3.plx'; %PS-.5/.4
%SPIKEtargetfile = '171218_E2_SSEP4.plx'; %PS-.5/.4
%SPIKEtargetfile = '171218_E2_SSEP5.plx'; %Battery-2/.4
%SPIKEtargetfile = '171218_E2_SSEP6.plx'; %Battery-1/.4 ?
%SPIKEtargetfile = '171218_E2_SSEP7.plx'; %Battery-4/.4
%SPIKEtargetfile = '171218_E2_SSEP8.plx'; %Battery-.1/.4
%SPIKEtargetfile = '171218_E2_SSEP9.plx'; %Battery-.01/.4
%SPIKEtargetfile = '171218_E2_SSEP10.plx';%Battery-1/.4
%SPIKEtargetfile = '171218_E2_SSEP11.plx';%Battery- 2/.2
%SPIKEtargetfile = '171218_E3_SSEP1.plx'; %PS-2/.4
%SPIKEtargetfile = '171218_E3_SSEP2.plx'; %PS-2/.4
%SPIKEtargetfile = '171218_E3_SSEP3.plx'; %PS-2/.4
%SPIKEtargetfile = '171218_E3_SSEP4.plx'; %PS-.1/.4
%SPIKEtargetfile = '171218_E3_SSEP5.plx'; %PS-.01/.4


fieldCh = [0:16];            % Specify the channels that contain field (LFP or EFP) recordings

%
filenames = dir(SPIKEtargetfile);
filename = strtok(filenames(1).name,'.');
fielddata = import_plexon_analog([pwd '/'], filename, fieldCh); %Import LFPs
fielddata.timeframe = fielddata.timestamps(1) + single(0:1/fielddata.freq(1):(length(fielddata.data)-1)/fielddata.freq(1));
%ts = mytimeseries;
%ts.Data = fielddata.data'; 
%ts.Time = fielddata.timeframe;

%

alltdat = [];
dat = fielddata.data';

% dat = right_dat;
%stimind_t = find(abs(dat(:,17)) > .1); 
stimind_t = find(dat(:,17) > .1); 


j=1;
for i = 1:length(stimind_t)-1
    if stimind_t(i+1) - stimind_t(i) > 1000
        stimind(j) = stimind_t(i);
        j = j+1;        
    end    
end

% dat = left_dat;
% stimind = find(abs(dat(:,17)) > .1); 

dt = mean(diff(fielddata.timeframe));
nstim = length(stimind)
ind1 = 500;
ind2 = 500;
for jj = 1:16
    subplot(4,4,jj)
    for ii = 1:nstim
        tdat = dat((stimind(ii)-ind1):(stimind(ii)+ind2),jj);
        alltdat(ii,:) = tdat;
    end
    hold on
    tind = (-ind1:ind2)/2;
    
    plot(tind,mean(alltdat),'r');   
    a = axis;
    axis([tind([1 end]) a(3:4)])
end
subplot(4,4,1)
title(strrep(SPIKEtargetfile,'_',' '))
savefig([strrep(SPIKEtargetfile,'.plx','') '_avg.fig'])