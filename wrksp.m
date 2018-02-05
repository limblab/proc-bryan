[an_data,~] = import_plexon('E1_1800117_SSEP3.plx')
% params.binSize = 0.05;
% params.data_ch = [0:15 32:47];
% params.freqBands = [8 20; 20 70; 70 130; 130 200; 200 300]; 
% params.LFPwindowSize = 256;
% params.FFTwindowSize = 256;
% params.nFFT = 256;
% an_data = do_LFPanalysis_funct(an_data,params);

figure(1)
y = (1:1:size(an_data.data,2))/1000;
ax1 = subplot(5,1,1)
plot(y,an_data.data(2,:))
title(ax1,'VL')
ax2 = subplot(5,1,2)
plot(y,an_data.data(4,:))
title(ax2,'GS')
ax3 = subplot(5,1,3)
plot(y,an_data.data(5,:))
title(ax3,'BFp')
ax4 = subplot(5,1,4)
plot(y,an_data.data(6,:))
title(ax4,'LG')
ax5 = subplot(5,1,5)
plot(y,an_data.data(7,:))
title(ax5,'TA')
linkaxes([ax1,ax2,ax3,ax4,ax5],'x');



temp = an_data;

lags = zeros(32,3);
for i = 1:32
    [acor,lag] = xcorr(sp_data(i).fr,spikes(:,i+1)');

    [lags(i,3),I] = max(abs(acor));
    lags(i,1) = lag(I);
    lags(i,2) = lags(i,1)/20;
end

lagstr = zeros(201,32);
testlag = 1;
for i = 1:32
    [acor,lag] = xcorr(sp_data(i).fr,spikes(:,i+1)');
    for j = -100:100
        lagstr(j+101,i) = acor(find(lag == j))/lags(i,3);    
    end
end
plot(-100:100,lagstr)

%figure
%plot(lag,acor)
%a3 = gca;
%a3.XTick = sort([-3000:1000:3000 lagDiff]);


stim_ts = find(abs(temp.data(18,:))> 2);
tim = [stim_ts(1)];
for h = 2:length(stim_ts)
    if stim_ts(h) - tim(end) > 8
        tim(end+1) = stim_ts(h);
    end
end

L = 1/0.05;
ch = 1;
stim_av = zeros(L,1);
for i = stim_ts
    sts = floor(i / 20);
    for j = 1:L
        stim_av(j) = stim_av(j) + sp_data(ch).fr(sts + j - 1);  
    end
end 
stim_av = stim_av/length(stim_ts);
plot(stim_av')

L = 2000;
stim_av = zeros(17,L);
for i = stim_ts
    for j = 1:L
       stim_av(17,j) = stim_av(17,j) + abs(temp.data(17,i + j - 1));
       for k = 1:16
          stim_av(k,j) = stim_av(k,j) + temp.rawEpiduralData.rawEpidural(k,i + j - 1);
       end    
    end
end 
stim_av = stim_av/length(stim_ts);

plot(0:0.5:L/2 - 0.5,stim_av')
title('E2 left leg')
xlabel('ms')
ylabel('mV')

y = fft(an_data.data(34,:));
power = abs(y).^2/958187;
plot((0:958186)*(2000/958186),power)


temp = an_data.data(34,:);
[b,a] = butter(2,[58 62]/(1000),'stop');
temp = filtfilt(b,a,double(temp)')';

resa = zeros(32,3)
resb = zeros(32,3)

for i = 1:32
    [acor,lag] = xcorr(an_data.filteredEpiduralData.CAR2(i,:),temp,20000);
    [b,a] = butter(2,[178 182]/(1000),'stop');
    acor = filtfilt(b,a,double(acor)')';
    [M,I] = max(abs(acor));
    resa(i,3) = lag(I)/2;
    resb(i,3) = M;
    plot(lag, acor)
end

ekg_ts_temp = find(abs(an_data.data(34,:)) > 0.2) - 50;
i = 2;
ekg_ts(1,1) = ekg_ts_temp(1,1);
for h = 2:length(ekg_ts_temp)
    if (ekg_ts_temp(1,h) - ekg_ts(1,i-1)) > 200
        ekg_ts(1,i) = ekg_ts_temp(h);
        i = i + 1;
    end
end

L = 400;
ekg_av = zeros(1,L);
for i = ekg_ts
    if i + L < length(an_data.data(34,:))
        for j = 1:L
            ekg_av(1,j) = ekg_av(1,j) + an_data.data(34,i + j - 1);
        end
    end
    %plot(an_data.data(34,i:i + L))
    %pause();
end 
ekg_av = ekg_av/length(ekg_ts);
plot(ekg_av)

resa = zeros(32,3);
resb = zeros(32,3);

for i = 1:32
    [acor,lag] = xcorr(an_data.filteredEpiduralData.rawEpidural(1,:),an_data.data(34,:),20000,'coeff');
    %[b,a] = butter(2,[178 182]/(1000),'stop');
    %acor = filtfilt(b,a,double(acor)')';
    [M,I] = max(abs(acor));
    resa(i,2) = lag(I)/2;
    resb(i,2) = M;
    %plot(lag, acor)
end

y = fft(acor);
L = length(acor);
power = abs(y).^2/L;
plot((0:(L-1)/2)*(2000/L),power(1:(L+1)/2))

lags = [];
for j = 1:16
    temp_data = spikedata(j).ts;
    for i = 2:length(temp_data) 
        %if temp_data(i)-temp_data(i-2) < .99 & temp_data(i) - temp_data(i-1) < 0.01
        lags(end+1) = temp_data(i)-temp_data(i-1);
            %fprintf('%d:%d\n',i-2,lags(end));
        %end
    end
end
edges = [0:0.001:0.1 0.15:0.05:1 10];
histogram(lags,edges)

lags = [];
for j = 1:16
    temp_data = spikedata2(j).ts;
    for i = 1:length(temp_data)
        [m,p] = min(abs(temp_data(i) - stimind_t2));
        if temp_data(i) - stimind_t2(p) < 0
            m = -1 * m;
        end
        lags(end+1) = m;    
    end
end
edges = [-1:0.001:1];
histogram(lags,edges)

