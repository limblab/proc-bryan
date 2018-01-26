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
% or a mat file containing the correct structure
%
% Once recording has finished the function will collect all of the relevant
% files into a single .mat file in the directory defined in StimParams
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
%   I've set up the closing function to open all of the binary files and
%   re-store the data and parameters as .mat file. Should we delete the
%   binary files afterwards?
%
%
% TIPS:
%
%
% TODO:
%   - Fix issues with PL_GetPars (BY)
%   - Start external plexon recording automatically (KB)
%   - preallocate ts list for speed (BY) // what does this mean? KB
%   - Rewrite the initialization routine to remove errors (KB)
%
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
try
    [wStim,pRead] = setupCommunication(bmi_params);
catch
    close_realtime_Wrapper(pRead,wStim)
end


%% initialize visualization

keepRunning = msgbox('Press ''ok'' to quit'); % handle to end stimulation

if bmi_params.display_plots
    stimFig.fh = figure('Name','FES Commands'); % setup visualization of stimulation
    stimFig = stim_fig(stimFig,[],[],bmi_params.bmi_fes_stim_params,'init'); % using the old stim fig code
end



%% Create folder for saving, create .csv files
dd = datetime; % current date and time
dd.Format = 'dd-MMM-uuuu_HH:mm'; % change how it displays
dirName = [bmi_params.save_dir,'\',bmi_params.save_name,'_',datestr(dd,30)];
if ~exist(dirName)
    mkdir(dirName);
end

bmi_params.save_dir = dirName;

spFile = [dirName '\Spikes.stm'];
predFile = [dirName, '\EMG_Preds.stm'];
stimFile = [dirName, '\Stim.stm'];

spPointer = fopen(spFile,'w');
predPointer = fopen(predFile,'w');
stimPointer = fopen(stimFile,'w');

clear *Header dd dirName
%% start loop

loopCnt = 0; % loop counter for S&G -- might want to do some variety of catch later on.
% trialCnt = 0; % trial number for catch trials for the monkey. 
tStart = tic; % start timer
tLoopOld = toc(tStart); % initial loop timer 
load(bmi_params.neuron_decoder); % load the neuron decoder into a separate structure because.
% load('C:\Users\bly0753\Downloads\N8_171219_decoderModel.mat');
neuronDecoder = model;
clear model;
% catchTrialInd = randperm(100,bmi_params.bmi_fes_stim_params.perc_catch_trials); % which trials are going to be catch
binsize = bmi_params.emg_decoder.binsize; % because I'm lazy and don't feel like always typing this.


drawnow; % take care of anything waiting to be executed, empty thread

stimAmp = zeros(length(bmi_params.bmi_fes_stim_params.PW_min));
stimPW = zeros(length(bmi_params.bmi_fes_stim_params.PW_min));


fRates = zeros(neuronDecoder.fillen/neuronDecoder.binsize,length(neuronDecoder.neuronIDs));

try
while ishandle(keepRunning)
    
    
    %% wait necessary time for loop
    tLoopNew = toc(tStart);
    tLoop = tLoopNew - tLoopOld;
    
    if ((tLoop+.02) < binsize) && bmi_params.display_plots % if we have more than 20 ms extra time, update the stim figure
        stimFig = stim_fig(stimFig,stimPW,stimAmp,bmi_params.bmi_fes_stim_params,'exec');
        tWaitStart = tic; % Wait loop time
        while (toc(tWaitStart) + tLoop) < binsize
            drawnow;    % empty process
        end
    elseif tLoop < binsize 
        tWaitStart = tic;
        while toc(tWaitStart) < tLoop
            drawnow;    % empty process
        end
    elseif tLoop > binsize
        warning('Slow loop time: %f',tLoop) % throw a warning 
    end
    
    tLoopOld = toc(tStart); % reset timer count
    
    %% collect data from plexon, store in csv
    new_spikes = get_New_PlexData(pRead, bmi_params);
    fRates = [new_spikes; fRates(1:end-1,:)];
    
    tempdata = [tLoopOld,new_spikes];
    fwrite(spPointer,tempdata,'double');
%     save(spFile,'tempdata','-ascii','-tabs','-append')
    
    
    %% predict from plexon data, store in csv
    emgPreds = [1 fRates(:)']*neuronDecoder.H;
    
    % implement static non-linearity
    if isfield(neuronDecoder,'P') % do we have non-static linearities
        nonlinearity = zeros(1,length(emgPreds));
        for ii = 1:length(emgPreds)
            nonlinearity(ii) = polyval(neuronDecoder.P(:,ii),emgPreds(ii));
        end
        emgPreds = nonlinearity;
    end
    
    % save these into the csv -- change to save()
    tempdata = [tLoopOld,emgPreds];
    fwrite(predPointer,tempdata,'double');
%     save(predFile,'tempdata','-ascii','-tabs','-append')
    
    %% convert predictions to stimulus params, store in csv
    
    % if we're going to do catch trials for the monkeys, we're gonna need
    % to interact with the XPC. This will depend on whether we're using the
    % same code base for both systems.
    % -- insert here if needed --
    
    % Get the PW and amplitude
    [stimPW, stimAmp] = EMG_to_stim(emgPreds, bmi_params.bmi_fes_stim_params); % takes care of all of the mapping
    
    if strcmp(bmi_params.bmi_fes_stim_params.mode,'PW_modulation')
        tempdata = [toc(tStart),stimPW];
        fwrite(stimPointer,tempdata,'double');
    else
        tempdata = [toc(tStart),stimAmp];
        fwrite(stimPointer,tempdata,'double');
    end
    
    
    %% send stimulus params to wStim
    
    [stimCmd, channelList]    = stim_elect_mapping_wireless( stimPW, ...
                                    stimAmp, bmi_params.bmi_fes_stim_params );
    for whichCmd = 1:length(stimCmd)
        wStim.set_stim(stimCmd(whichCmd), channelList);
    end
    
    
%% update loop count, 
    loopCnt = loopCnt + 1;


end

catch ME
    display(ME)
    warning('Could not run stimulation loop, shutting down')
end

close_realtime_Wrapper(pRead,wStim,bmi_params,stimFig,stimPointer,predPointer,spPointer);

end


%%
function close_realtime_Wrapper(pRead,wStim,bmi_params,stimFig,stimPointer,predPointer,spPointer)

if exist(stimFig)
    close(stimFig.fh)
end

if exist('stimPointer') & exist('predPointer') & exist('spPointer')
% get the filenames for the binary files, reopen them for reading, and
% store all of the data into a matlab structure, then save it.

    % get the names for the files, close the files
    [stimFile,~,~,~] = fopen(stimPointer);
    [predFile,~,~,~] = fopen(predPointer);
    [spFile,~,~,~] = fopen(spPointer);
    fclose(stimPointer);
    fclose(predPointer);
    fclose(spPointer);
    
    % all the information about the file size
    spFileInfo = dir(spFile);
    predFileInfo = dir(predFile);
    stimFileInfo = dir(stimFile);
    
    % reopen the files for reading
    stimPointer = fopen(stimFile,'r');
    predPointer = fopen(predFile,'r');
    spPointer = fopen(spFile,'r');
    
    % Organize all of the EMG data
    EMGs = struct('Name',[],'BinLength',[],'Preds',[],'ts',[]);
    EMGs.Name = bmi_params.bmi_fes_stim_params.muscles;
    EMGs.BinLength = bmi_params.emg_decoder.binsize;
    EMGs.Preds = fread(predPointer,predFileInfo.bytes,'double');
    EMGs.Preds = reshape(EMGs.Preds,numel(bmi_params.bmi_fes_stim_params.muscles)+1,predFileInfo.bytes/numel(bmi_params.bmi_fes_stim_params.muscles)+1);
    EMGs.ts = EMGs.Preds(:,1);
    EMGs.Preds = EMGs.Preds(:,2:end);
    
    % Organize all the Stim Params
    Stims = struct('Name',[],'Vals',[],'ts',[]);
    Stims.Name = bmi_params.bmi_fes_stim_params.muscles;
    Stims.Vals = fread(stimPointer,stimFileInfo.bytes,'double');
    Stims.Vals = reshape(Stims.Vals,numel(bmi_params.bmi_fes_stim_params.muscles)+1,stimFileInfo.bytes/numel(bmi_params.bmi_fes_stim_params.muscles)+1);
    Stims.ts = Stims.Vals(:,1);
    Stims.Vals = Stims.Vals(:,2:end);
    
    % And finally, spikes
    Spikes = struct('Electrode',[],'fRate',[],'ts',[]);
    Spikes.Electrode = bmi_params.neuronIDs;
    Spikes.fRate = fread(spPointer,spFileInfo.bytes,'double');
    Spikes.fRate = reshape(Spike.fRate,bmi_params.n_neurons+1,spFileInfo.bytes/bmi_paramsn_neurons+1);
    Spikes.ts = Spikes.fRate(:,1);
    Spikes.fRate = Spikes.fRate(:,2:end);
    
    % Save all the info in a file together, and the stimulation params
    storageFN = [bmi_params.save_dir, filesep, 'recordedData.mat'];
    paramsFN = [bmi_params.save_dir, filesep, 'params'];
    save(storageFN,'Spikes','Stims','EMGs');
    save(paramsFN,'bmi_params');
    
    
    % close all of the files
    % (do we want to delete the binary files?)
    fclose(spPointer); fclose(stimPointer); fclose(predPointer);
    
end
    

%Close connection
PL_Close(pRead);
wStim.delete();
fclose(instrfind);
instrreset % this seems to work better at purging the list of connected serial ports

'Exited Properly'

end