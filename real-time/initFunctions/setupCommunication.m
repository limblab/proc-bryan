function [wStim,pRead] = setupCommunication(StimParams)
% --- setupCommunication(StimParams) ---
%
% Loads the relevant information from StimParams to open a Plexon socket
% and a Ripple wireless_stim object. This is designed to be a subfunction
% for running bmi-FES, not as a standalone function
%
% -- inputs --
% StimParams        Defined per setupStimParams
% 
% -- outputs --
% wStim             wireless_stim object, per Ripple
% pRead             Plexon socket handler, per Plexon


%% Plexon connection
pRead = PL_InitClient(0);
if pRead == 0
    error('Unable to connect, exiting now');
end
pause(0.05);



%% Ripple        

stim_params = struct('dbg_lvl',1,'comm_timeout_ms',-1,'blocking',true,'zb_ch_page',17,'serial_string',params.bmi_fes_stim_params.port_wireless)
wStim  = wireless_stim(stim_params);

        try
            % Switch to the folder that contains the calibration file
            cur_dir = pwd;
            cd( params.bmi_fes_stim_params.path_cal_ws );
            
            % see how old the calibration file is. If it's over a week old,
            % make a new one
            D = dir;
            cmp = strcmpi({D.name},wStim.trim_cal_fname);
            if (now-D(cmp).datenum)>7
                warning('Trim calibration file is over a week old. Building new one');
                recycle(D(cmp).name); % toss old trim_cal in the recycling
            end
             
            
            wStim.init();

            wStim.version();      % print version info, call after init
            
            % TEMP: go back to the folder you were
            cd(cur_dir)
            
            if stim_params.dbg_lvl ~= 0
                % retrieve & display settings from all channels
                channel_list    = 1:wStim.num_channels;
                commands        = wStim.get_stim(channel_list);
                wStim.display_command_list(commands, channel_list);
            end
            
            % set up the stimulation params that will not be modulated
            % (frequency, polarity, amplitude/PW [depending on the stim
            % mode] ...)
            % this will work only if the bmi and bmi_stim folders are on
            % the path. HAHAHA
            setup_wireless_stim_fes(wStim, params.bmi_fes_stim_params);
            
        % if something went wrong close communication with Central and the
        % stimulator and quit
        catch ME
            delete(wStim);
            cbmex('close');
            rethrow(ME);
        end
end