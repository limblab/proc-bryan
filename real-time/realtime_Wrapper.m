function realtime_Wrapper(StimParams)
% --- realtime_Wrapper(StimParams) ---
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
% StimParams        structure or name for file with stimulation params. 
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
%   can -- their setting structures, for example, are pretty well set up.
%
% TIPS:
%
%
% TODO:
%   - Fix issues with PL_GetPars (BY)
%   - preallocate ts list for speed (BY) // what does this mean? KB
%   - Initial skeleton of code we can work from (KB)
%   - 
%
% Author(s): Bryan Yoder, Kevin Bodkin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Load StimParams
% load StimParams, use defaults if not specified
if exist('StimParams')
    [StimParams,loadError] = setupStimParams(StimParams); % this will be similar to the old defaultStimParams code
else
    [StimParams,loadError] = setupStimParams;
end
if ~isempty(loadError)
    error(loadError) % kick us out of the function if necessary
end

%% Set up stim and plexon
% handles for plexon and Ripple objects
[wStim,pRead] = setupCommunication(StimParams);



%% initialize visualization

keepRunning = []; % this will be the handle for vizualization





%% 


%% start loop


tStart = tic;
while ishandle(keepRunning)
    
    
    % wait necessary time for a 50 ms loop
    tLoopNew = toc;
    tLoop = tLoopNew - tLoopOld;
    tLoopOld = tLoopNew;
    
    if tLoop < ***binsize*** % change to StimParams field
        pause(***binsize*** - tLoop); % make sure loop takes full binsize
    elseif tLoop > ***binsize***
        warning('Slow loop time: %f',tLoop)
    end
    
    
    % collect data from plexon, store in csv
    
    
    
    % predict from plexon data, store in csv
    
    
    
    % convert prections to stimulus params, store in csv
    
    
    
    % send stimulus params to wStim
    
    
    

    
    
    
    


%Variable set-up
bin_size = 0.05; % this will be in StimParams
cur_ts = [];
cur_bin_ts = 0;

sp_bins = [];


%Gets initial timestamp, will loop until it acquires 1
%TODO: Remove this and come up with better way
% KB: what is this supposed to do?
while 1
    [n,cur_ts] = PL_GetTS(pRead);   
    if n
        break;
    end
end
cur_bin_ts = bin_size * floor(cur_ts(1,4) / bin_size);

%pars = PL_GetPars(s) %Doesn't work over PlexNet
                      %Also returns incorrect adc rate sometimes? look into

b = tic
while toc(b)<5
    [n, ts] = PL_GetTS(pRead); %Gets
    if n
        cur_ts = [cur_ts; ts]; %sorted by time (TODO: ensure this is always
                               %true or add error checking)       
    end
    
    % Collected enough for a bin, so bin it
    if cur_ts(end,4)-cur_bin_ts > bin_size
        %increment by only 1 bin size to ensure no bins are missed
        %a = tic;
        cur_bin_ts = cur_bin_ts + bin_size;
        [nts, cur_bin] = bin_PlexNet(cur_ts,cur_bin_ts);
        sp_bins = horzcat(sp_bins,cur_bin);
        cur_ts = cur_ts(nts,:);        
        %fprintf('Time: %f , Num: %d , Ratio: %e\n',toc(a),nts-1,(toc(a)/(nts-1)));
    end
end


%Close connection
PL_Close(pRead);
pRead = 0;








end