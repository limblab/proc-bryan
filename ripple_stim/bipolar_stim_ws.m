function [ output_args ] = bipolar_stim_ws(amp, pw, tl, freq, ch_list)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

stim_params = struct('dbg_lvl',1,'comm_timeout_ms',15,'blocking',true,'zb_ch_page',2,'serial_string','COM5');

ws  = wireless_stim(stim_params);

ws.init();
ws.version();

%% 
ch_list         = 1:16;
stim_PW         = 1000*stim_PW;     % Pulse width converted
stim_amp        = repmat(1000*stim_amp,size(channels,2));
chs_cmd         = 1:ws.num_channels;
AMP_OFFSET      = 32768;

ws.set_Freq(freq, chs_cmd );
ws.set_TD( 50,chs_cmd ); % minimum allowed is 50 us -- see below for additional notes on this KB 07/14/2017

ws.set_AnodAmp( AMP_OFFSET, chs_cmd ); % set to zeros
ws.set_CathAmp( AMP_OFFSET, chs_cmd );

% define arrays with the anodes and cathodes
anode_list      = channels(1,:);
cathode_list    = channels(2,:);
               
% the zigbee command has to include all 16 channels
% here we add all the channels (even those we are not
% stimulating) and set up their stimulation amplitudes
pw_cmd         = zeros(1,length(chs_cmd));
pw_cmd(anode_list)     = stim_PW;
pw_cmd(cathode_list)   = stim_PW;
                
% set amplitude -- done in a different command because of
% limitations in command length (register write in zigbee)
ws.set_AnodDur( pw_cmd, chs_cmd );
ws.set_CathDur( pw_cmd, chs_cmd );
                
% Set polarity for the anodes...
% Set polarity to anodic first
ws.set_PL( 0, anode_list );
% ... and for the cathodes
% Set polarity to anodic first
ws.set_PL( 1, cathode_list );
                
% set to run continuous
ws.set_Run( ws.run_cont, anode_list );
ws.set_Run( ws.run_cont, cathode_list );

%%

% assign it to the corresponding stim anode and cathode
% elecs_this_muscle = zeros(1,length(channels));
% for i = 1:length(channels/2)
%     elecs_this_muscle(i) = bmi_fes_stim_params.anode_map{1,i};
% end
% for i = 1:length(channels/2)
%     elecs_this_muscle(i+length(stim_PW)) = bmi_fes_stim_params.cathode_map{1,i};
% end
  
% add the channels we are not stimulating to the command,
% and populate their amp with zeroes
% --the wireless stimulator expect a 16-channel command
amp_cmd          = zeros(1,length(ch_list));
amp_cmd(anode_list)     = stim_amp;
amp_cmd(cathode_list)   = stim_amp;
cmd_Cath = amp_cmd + AMP_OFFSET;
cmd_Anod = AMP_OFFSET - amp_cmd;

% create the stimulation command. 
cmd{1}          = struct('CathAmp', cmd_Cath, 'AnodAmp', cmd_Anod);
ws.set_stim(cmd(1),ch_list)
tic;
while toc < tl/1000
%     for whichCmd = 1:length(cmd)
    ws.set_stim(cmd(1), ch_list);
%     end
end

ws.set_Run(ws.run_stop, channels);


end
