function realtime_Wrapper(bmi_params)
% --- realtime_Wrapper(bmi_params) ---
%
% A single function that will take care of running all of code necessary
% for real-time stimulation in the rat, using the Plexon map server system
% and the Ripple wireless stimulator. 
%
% This function will take a prebuilt decoder (currently only accepts
% filters using a combination of FilMIMO4 and polyval. Refer to each
% respective function for more information) then apply it to real-time
% recordings from the plexon, then send those to the stimulator. It
% requires an input of StimParams, which can either be a matlab structure
% or a file of the appropriate variety *** TO BE DEFINED - MAYBE XML OR
% CSV? ***
%
% Once recording has finished the function will collect all of the relevant
% files into a single .zip(?) file in the directory defined in StimParams
%
%
% -- Inputs -- 
% bmi_parmas        structure or name for file with stimulation params. 
%
% -- Outputs --
% None directly through the function, though it will store all relevant
% recordings together
%
% 
% Authors: Bryan Yoder, Kevin bodkin



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -- Final goal --
% Wrapper script to import live Plexon data, bin it, decode EMG from
% LFPs and spike timestamps, and stimulate.
%
% Comments: 
% Let's put all of the initialization code in a subfunction --
%   IE have a separate function take care of opening the plexon and
%   WirelessStim objects - remember, this is supposed to be a wrapper
%
%   Also, I'm thinking we should use the old runBMIFES code as much as we
%   can -- for the time being I'm just going to use their bmi_params and
%   stim_params structures and initialization code
%
% TIPS:
%
%
% TODO:
%   - Fix issues with PL_GetPars (BY)
%   - preallocate ts list for speed (BY) // what does this mean? KB
%   - Initial skeleton of code we can work from (KB)
%   - Initial visualization of code (KB)
%   - shamelessly copy old StimParams struct, adjust (KB)
%   - Test and finish binning algorithm and artifact removal (BY)
%
% TODONE:
%   - Comment framework to build code around
%
%
%
% Author(s): Bryan Yoder, Kevin Bodkin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Load StimParams
% load StimParams, use defaults if not specified
try
    if ~exist('bmi_params')
        bmi_params = []; % this will be similar to the old defaultStimParams code
    end
    
    bmi_params = bmi_params_defaults(bmi_params);
catch ME
    error(ME) % kick us out if necessary
end

%% Set up stim and plexon
% handles for plexon and Ripple objects
[wStim,pRead] = setupCommunication(bmi_params);



%% initialize visualization

keepRunning = msgbox('Press ''ok'' to quit'); % this will be the handle for vizualization





%% Create folder for saving, create .csv files
dd = datetime; % current date and time
dd.Format = 'dd-MMM-uuuu_HH:mm'; % change how it displays
dirName = ['.\',datestr(dd,30)];
mkdir(cd,datestr(dd,30));

spFile = fopen([dirName '\Spikes.csv'],'wt');
spikeHeader = num2cell(bmi_params.neuronIDs,2);
for ii = 1:length(spikeHeader)
    spikeHeader{ii} = num2str(spikeHeader{ii});
    spikeHeader{ii} = strrep(spikeHeader{ii},' ','_');
end
spikeHeader = strjoin(spikeHeader,',');
fprintf(spFile,['Time,', spikeHeader, '\n']);


predFile = fopen([dirName, '\EMG_Preds.csv'],'wt');
predHeader = strjoin(bmi_params.bmi_fes_stim_params.muscles,',');
fprintf(predFile,['Time,',predHeader,'\n']);


stimFile = fopen([dirName, '\Stim.csv'],'wt');
stimHeader = strjoin(bmi_params.bmi_fes_stim_params.EMG_to_stim_map(2,:),',');
fprintf(stimFile,['Time,',stimHeader,'\n']);

clear *Header dd dirName
%% start loop


tStart = tic;
tLoopOld = toc;
fRates = zeros(ceil(bmi_params.emg_decoder.fillen/bmi_params.emg_decoder.binsize),length(bmi_params.bmi_fes_stim_params));
while ishandle(keepRunning)
    
    
    %% wait necessary time for a 50 ms loop
    tLoopNew = toc;
    tLoop = tLoopNew - tLoopOld;
    
    if tLoop < bmi_params.emg_decoder.binsize % change to StimParams field
        pause(bmi_params.emg_decoder.binsize - tLoop); % make sure loop takes full binsize
    elseif tLoop > bmi_params.emg_decoder.binsize
        warning('Slow loop time: %f',tLoop)
    end
    tLoopOld = toc; % reset for this coming loop
    
    %% collect data from plexon, store in csv
    [new_spikes, ts_old] = get_New_PlexData(pRead, ts_old, bmi_params);
    fRates = [new_spikes'; fRates(1:end-1,:)];
    %fRates = [get_firing_rates(pRead,bmi_params); fRates(2:end-1,:)]; % a subfunction below to get the (cleaned) firing rates
    fprintf(spFile,'%f',tLoopOld,fRates(1,:))
    fprintf(spFile,'\n')
    
    
    %% predict from plexon data, store in csv
    
    
    
    %% convert prections to stimulus params, store in csv
    
    
    
    %% send stimulus params to wStim
    
    
    

    
    
    

%Gets initial timestamp, will loop until it acquires 1
%TODO: Remove this and come up with better way
% KB: what is this supposed to do?
% BY: I'll probably get rid of it. Need to find a good way to get system
% time from Plexon
%while 1
%    [n,cur_ts] = PL_GetTS(pRead);   
%    if n
%        break;
%    end
%end
%cur_bin_ts = bin_size * floor(cur_ts(1,4) / bin_size);

%pars = PL_GetPars(s) %Doesn't work over PlexNet
                      %Also returns incorrect adc rate sometimes? look into







end

%Close connection
PL_Close(pRead);
pRead = 0;