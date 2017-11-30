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
% bmi_params        structure or name for file with stimulation params. 
%
% -- Outputs --
% None directly through the function, though it will store all relevant
% recordings together
%
% 
% Authors: Bryan Yoder, Kevin Bodkin



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
%   - Initial visualization of code (KB)
%   - Test and finish binning algorithm and artifact removal (BY)
%
% TODONE:
%   - Comment framework to build code around
%   - Initial skeleton of code we can work from (KB)
%   - shamelessly copy old StimParams struct, adjust (KB)
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Load StimParams
% load StimParams, use defaults if not specified
try
    if ~exist('bmi_params')
        bmi_params = struct(); % set up an empty structure to pass in
    end
    
    bmi_params = bmi_params_defaults(bmi_params);
catch ME
    error(ME) % kick us out if necessary
end

%% Set up stim and plexon
% handles for plexon and Ripple objects
[wStim,pRead] = setupCommunication(bmi_params);



%% initialize visualization

keepRunning = msgbox('Press ''ok'' to quit'); % handle to end stimulation

if bmi_params.display_plots
    stimFig = figure('Name','FES Commands'); % setup visualization of stimulation
    stimFig = stim_fig(stimFig,[],[],bmi_params.bmi_fes_stim_params,'init'); % using the old stim fig code
end



%% Create folder for saving, create .csv files
dd = datetime; % current date and time
dd.Format = 'dd-MMM-uuuu_HH:mm'; % change how it displays
dirName = ['.\',datestr(dd,30)];
mkdir(cd,datestr(dd,30));

spFile = [dirName '\Spikes.csv'];
predFile = [dirName, '\EMG_Preds.csv'];
stimFile = [dirName, '\Stim.csv'];
% stimHeader = strjoin(bmi_params.bmi_fes_stim_params.EMG_to_stim_map(2,:),',');
% if strcmp(bmi_params.animal,'Monkey')&(bmi_params.bmi_fes_stim_params.perc_catch_trials>0)
%     fprintf(stimFile,['Time,',stimHeader,',Catch\n']);
% else
%     fprintf(stimFile,['Time,',stimHeader,',Catch\n']);
% end

clear *Header dd dirName
%% start loop

loopCnt = 0; % loop counter for S&G -- might want to do some variety of catch later on.
trialCnt = 0; % trial number for catch trials for the monkey. 
tStart = tic; % start timer
tLoopOld = toc; % initial loop timer 
fRates = zeros(ceil(bmi_params.emg_decoder.fillen/bmi_params.emg_decoder.binsize),length(bmi_params.bmi_fes_stim_params));
neuronDecoder = bmi_params.decoders.neuron_decoder; % load the neuron decoder into a separate structure because.
catchTrialInd = randperm(100,bmi_params.bmi_fes_stim_params.perc_catch_trials); % which trials are going to be catch
binsize = bmi_params.emg_decoder.binsize; % because I'm lazy and don't feel like always typing this.


drawnow; % take care of anything waiting to be executed, empty thread

stimAmp = zeros(length(bmi_params.bmi_fes_stim_params.PW_min));
stimPW = zeros(length(bmi_params.bmi_fes_stim_params.PW_min));


while ishandle(keepRunning)
    
    
    %% wait necessary time for a 50 ms loop
    tLoopNew = toc(tStart);
    tLoop = tLoopNew - tLoopOld;
    
    if tLoop+.02 < binsize % if we have more than 20 ms extra time, update the stim figure
        stimFig = stim_fig(stimFig,stimPW,stimAmp,bmi_params.bmi_fes_stim_params,'exec')
        tWaitStart = tic; % Wait loop time
        while (toc(tWaitStart) + tLoop) < binsize
            print('');    % empty process
        end
    elseif tLoop < binsize 
        tWaitStart = tic;
        while toc(tWaitStart) < tLoop
            print('');    % empty process
        end
    elseif tLoop > binsize
        warning('Slow loop time: %f',tLoop) % throw a warning 
    end
    
    tLoopOld = toc(tStart); % reset timer count
    
    %% collect data from plexon, store in csv
    [new_spikes, ts_old] = get_New_PlexData(pRead, ts_old, bmi_params);
    fRates = [new_spikes'; fRates(1:end-1,:)];
    fprintf(spFile,'%f',tLoopOld,new_spikes')
    fprintf(spFile,'\n')
    
    
    %% predict from plexon data, store in csv
    emgPreds = [1 rowvec(fRates)']*neuronDecoder.H;
    
    % implement static non-linearity
    if isfield(neuronDecoder,P) % do we have non-static linearities
        nonlinearity = zeros(1,length(emgPreds));
        for ii = 1:length(emgPreds)
            nonlinearity(ii) = polyval(neuronDecoder.P(:,ii),emgPreds(ii));
        end
        emgPreds = nonlinearity;
    end
    
    % save these into the csv -- change to save()
%     save(predFile,
%     fprintf(predFile,'%f',tLoopOld,emgPreds);
%     fprintf(predFile,'\n');
    
    %% convert predictions to stimulus params, store in csv
    
    % if we're going to do catch trials for the monkeys, we're gonna need
    % to interact with the XPC. This will depend on whether we're using the
    % same code base for both systems.
    % -- insert here if needed --
    
    % Get the PW and amplitude
    [stimPW, stimAmp] = EMG_to_stim(emgPreds, bmi_params.bmi_fes_stim_params); % takes care of all of the mapping
    
    
    
    
    %% send stimulus params to wStim
    
    [stimCmd, channelList]    = stim_elect_mapping_wireless( stimPW, ...
                                    stimAmp, params.bmi_fes_stim_params );
    for whichCmd = 1:length(stimCmd)
        handles.ws.set_stim(stimCmd(whichCmd), channelList);
    end
    
    
%% 
    loopCnt = loopCnt + 1;


end

close_realtime_Wrapper(pRead,wStim);

end



function close_realtime_Wrapper(pRead,wStim)
    
%Close connection
PL_Close(pRead);
wStim.delete();


clear pRead wStim

end