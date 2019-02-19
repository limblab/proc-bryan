%% set up the data and information
% LimbLab Path:
% limlabPath = 'C:\Users\Pablo_Tostado\Desktop\Northwestern_University\LimbLab_Repo\limblab_analysis';
% limlabPath = 'C:\Users\mct519\Documents\Data Analyses\Neilsen\LFP_Analysis\rat_bmi-master\plexon_import\limblab_analysis-master';
% addpath(genpath(limlabPath));

% this works, though there's a bit of a hassle with a few of the timeframes
% here - it still needs to be totally reconciled

[KINdat, KINtimes] = get_CHN_data(kinematicData,'binned');
[FIELDdat, FIELDtimes] = get_CHN_data(fielddata,'binned CAR',KINtimes);
[APdat, APtimes] = get_CHN_data(spikedata,'binned',KINtimes);
[EMGdat, EMGtimes] = get_CHN_data(emgdata,'binned',KINtimes);
binsize = mean(diff(KINtimes));
kinlabels = kinematicData.KinMatrixLabels;
 
%% if matrices have already been saved in a file
inputdata = EMGdat;
outputdata = Limb_Angle;
% outputdata = EMGdat(:,[1 2 3]);
outputtimes = KINtimes';
labels = {'Limb_Angle','q','w'};
binsize = 0.05;
 
%% choose which data to use for the decoder

inputdata = [APData];
% [mat,pcatemp,u] = pca(inputdata);
% inputdata = pcatemp(:,1:25);
outputdata = KINdat(:,end-2:end);
labels = kinlabels;
labels = {'stance_phase'};
temp = find_joint_angles(KINdat,kinlabels);
outputdata = temp.limbfoot;

outputdata = EMGdat(:,:);
outputtimes = KINtimes';
% labels = kinematicData.KinMatrixLabels(:,:);
% labels = {'EMG 3', 'EMG 6', 'EMG 7'};
% [b,a] = butter(2,2*(binsize/2),'high');
% outputdata = filtfilt(b,a,outputdata);  
% 
% outputdata = EMGdat(:,[3 6 7]);
 ind = find((outputdata) > 9999);
 outputdata(ind) = NaN;
inputdata(ind) = NaN;
outputtimes(ind) = NaN;

% % this is to censor the bad section of the file
%  useind = 70/binsize:(KINtimes(end)/binsize);
%  useind = (binsize/binsize):(420/binsize);
useind = (1:length(outputtimes))';

inputdata = inputdata(useind,:);
outputdata = outputdata(useind,:);
outputtimes = outputtimes(useind);
duration = outputtimes(end)-outputtimes(1);

%% do the decoding
binnedData = [];
ninputs = size(inputdata, 2);   % the number of channels in the input

% Set decoding parameters and predict kinematics

% Mandatory fields to specify the signal to decode 
DecoderOptions.PredEMGs = 0;             % Predict EMGs (bool)
DecoderOptions.PredCursPos = 1;          % Predict kinematic data (bool)

DecoderOptions.PolynomialOrder = 1;      % Order of Wiener cascade - 0 1 for linear
DecoderOptions.foldlength = 30;          % Duration of folds (seconds)
DecoderOptions.fillen = 0.5;             % Filter Length: Spike Rate history used to predict a given data point (in seconds). Usually 500ms.
DecoderOptions.UseAllInputs = 1;

% These parameters are standard in the LAB when using the Wiener decoder code:
binnedData.spikeratedata = inputdata2;
binnedData.neuronIDs = [ [1:ninputs]' zeros(ninputs, 1)];
binnedData.cursorposbin = outputdata2; %DECODING SIGNAL
binnedData.cursorposlabels = labels;
binnedData.timeframe = outputtimes2;

[PredSignal] = epidural_mfxval_decoding (binnedData, DecoderOptions);

% Save struct with predictions
% disp('Saving Offline Predictions...');
% an_data.wiener_offlinePredictions = PredSignal;
% 
% save([data_dir 'mat_files/' filename], 'an_data'); 

