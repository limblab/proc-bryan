%% Metadata
rat = fes_params.meta.Name;
muscle_list = fes_params.fes_stim_params.muscles;
L = size(Stims.Vals,1);
binsize = fes_params.binsize; %seconds


%% Stim stats
x = (0:floor((L-1)/2))*(1/binsize/(L-1));


fs = 1/binsize;
[pxx2,f] = pwelch(EMGs2.Preds,[],[],256,fs);
plot(repmat(f,1,7),log10(pxx3));
xlabel('Frequency (Hz)')
ylabel('PSD (dB/Hz)')
pxx3 = pxx2 - pxx;

figure(1);
for i = 1:length(muscle_list)
    stim_vals = Stims.Vals(:,i);
    
    nz_stim = stim_vals;
    nz_stim(stim_vals == 0) = []; 
    
    subplot(3,3,i);
    histogram(nz_stim);
    ytix = get(gca, 'YTick');
    set(gca, 'YTick', ytix, 'YTickLabel', floor(1000*ytix/L)/1000);    
    xlabel('Amplitude (mA)')
    title(muscle_list(i))
    hold on    
end


figure(2)
for i = 1:length(muscle_list)
    stim_vals = Stims.Vals(:,i);

    subplot(3,3,i);
    y = fft(stim_vals)/L;
    power = abs(y).^2/L;
    plot(x(5:end),power(5:ceil(L/2)));
    xlabel('Frequency (Hz)')
    title(muscle_list(i))
    hold on    
end

%% EMG Prediction stats
figure(3)
for i = 1:length(muscle_list)
    emg_vals = EMGs.Preds(:,i);

    subplot(3,3,i);
    y = fft(emg_vals)/L;
    power = abs(y).^2/L;
    plot(x(5:end),power(5:ceil(L/2)));
    xlabel('Frequency (Hz)')
    title(muscle_list(i))
    hold on    
end

figure(4)
for i = 1:32
    sp_vals = Spikes.fRate(:,i);

    subplot(6,6,i);
    y = fft(sp_vals)/L;
    power = abs(y).^2/L;
    plot(x(5:end),power(5:ceil(L/2)));
    xlabel('Frequency (Hz)')
    title(i)
    hold on    
end

fs = 1/binsize;
[pxx,f] = pwelch(Spikes.fRate,[],[],200,fs);
plot(repmat(f,1,32),log10(pxx));

