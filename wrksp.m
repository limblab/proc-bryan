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
ax1 = subplot(8,1,1)
plot(y,an_data.data(1,:))
title(ax1,'GS')
ax2 = subplot(8,1,2)
plot(y,an_data.data(2,:))
title(ax2,'VL')
ax3 = subplot(8,1,3)
plot(y,an_data.data(3,:))
title(ax3,'BFa')
ax4 = subplot(8,1,4)
plot(y,an_data.data(4,:))
title(ax4,'BFp')
ax5 = subplot(8,1,5)
plot(y,an_data.data(5,:))
title(ax5,'LG')
ax6 = subplot(8,1,6)
plot(y,an_data.data(6,:))
title(ax6,'TA')
ax7 = subplot(8,1,7)
plot(y,an_data.data(7,:))
title(ax7,'GND')
ax8 = subplot(8,1,8)
plot(y,an_data.data(8,:))
title(ax8,'IP')
linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8],'x');



temp = an_data;

%Cross correlation
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


%FFT
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

i=8;
figure(1);
plot(predData.timeframe,predData.actualData(:,i));
hold on;
plot(predData.timeframe,predData.preddatabin(:,i));

m = mean(EMGs.Preds);
s = std(EMGs.Preds);

i = 1;
plot(EMGs.ts,EMGs.Preds(:,i))
hold on
plot(EMGs.ts,m(i)*ones(length(EMGs.Preds),1))
hold on
plot(EMGs.ts,(m(i) + s(i))*ones(length(EMGs.Preds),1))
hold on
plot(EMGs.ts,(m(i) + 2*s(i))*ones(length(EMGs.Preds),1))
hold on
plot(EMGs.ts,(m(i) + 3*s(i))*ones(length(EMGs.Preds),1))


swing_Amp = [1.5,0,2.5,0,0,1,0,1.5];
stance_Amp = [0,2.5,0,3,1,0,0,0];
offcount = 0; totalcount = 0;
phase = zeros(1,length(EMGs.Preds));
flag = 0;
state = 'waiting';
n = 20;
NABOVE = 2;
NSWING = 5; %was originally at 10
NSTANCE = 10; %was originally at 20
THRESH = 1.5;
swingAve = zeros(nnz(swing_Amp),n);
stanceAve = zeros(nnz(stance_Amp),n);
for i = 1:length(EMGs.Preds())
     swingAve = [EMGs.Preds(i,find(swing_Amp));  swingAve(:,1:end-1)']';
     stanceAve = [EMGs.Preds(i,find(stance_Amp));  stanceAve(:,1:end-1)']';
     ratio = sum(sum(stanceAve))/sum(sum(swingAve));
     signal = ratio*sum(EMGs.Preds(i,find(swing_Amp)))/sum(EMGs.Preds(i,find(stance_Amp)));
     if signal > THRESH
         totalcount = totalcount + 1; 
     end
         
     switch state
        case 'waiting'
            phase(i) = 0;
            if signal > THRESH
                flag = flag + 1;
            else
                flag = 0;
            end
            
            if flag == NABOVE
                state = 'swing phase';
                disp('start swing')
                count = 0;
            end
        case 'swing phase'
            phase(i) = 1;
            count = count + 1;
            if count > NSWING
                state = 'stance phase';
                count = 0;
            end
        case 'stance phase'
            phase(i) = 2;
            if signal > THRESH
                offcount = offcount + 1; 
            end
            count = count + 1;
            if count > NSTANCE
                state = 'waiting';
                count = 0;
            end
     end     
end
plot(0.05:0.05:length(EMGs.Preds)/20,phase)
offcount
totalcount