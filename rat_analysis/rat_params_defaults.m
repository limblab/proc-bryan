function rat_params = rat_params_defaults(rat_params)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

rat_params_defaults = struct( ...
    'path'      ,'C:\Users\limblab\Documents\Raw Data\plx_files',...
    'plx_file'  ,'N20_180712_noobstacles.plx',...
    'kin_file'  ,'18-07-12_noobstacles_noEMG.xlsx',...
    'rat'  ,'N20',...
    'date'  ,'18-07-12',...
    'viconCh'  ,16,...
    'sorted'   ,0,...
    'spikeCh'  ,[1:16 33:48],...
    'fieldCh'  ,[0:15 32:47],...
    'viconScalingFactor' , 4.7243,...  % Factor to convert Vicon kinematics to mm.% this is now in the file reading - should be updated
    'viconFreq' , 200,...              % Frequency (Hz) at which kinematic data is acquired. Necessary to bin data. EXTRACT THIS FROM THE XLS FILE IF POSSIBLE
    'referenceMarker' ,'hip_middle',...
    'binSize' , 0.05,...               % Bin size for binning the data (in seconds): 0.05 = bins of 50ms
    'LFPwindowSize' , 256,...          % Size of the window used to bin the data. Trade off between freq resolution & window overlapping
    'FFTwindowSize' , 256,...          % Size of the FFT window. Divide data into overlapping sections of the same window length to compute PSD.
    'nFFT' , 256,...                   % Number of FFT points used to calculate the PSD estimate(make it power of 2 for faster processing). nFFT larger than the window of data (FFTwindowSize) will result in zero-padding the data.
    'freqBands' , [8 19; 20 69; 70 129; 130 199; 200 300]);


all_param_names = fieldnames(rat_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(rat_params,all_param_names(i))
        rat_params.(all_param_names{i}) = rat_params_defaults.(all_param_names{i});
    end
end

end

