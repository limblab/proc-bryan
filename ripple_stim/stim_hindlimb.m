function [ output_args ] = stim_hindlimb(varargin)

%Set up params
freq = 40;
stim_PW = 0.2;
num_steps = 3;

%Set up stimulator
stim_params = struct('dbg_lvl',1,'comm_timeout_ms',15,'blocking',false,'zb_ch_page',2,'serial_string','COM4');

ws  = wireless_stim(stim_params);

ws.init();
ws.version();

for i = 1:num_steps
    %Stim Flexor Muscles
    flex_amps = [1.5 2 2 .75 .75]; %ma
    flex_tl = 333; %ms
    flex_ch = [1 5 7 11 13;2 6 8 12 14];
    bipolar_stim_cont(ws, flex_amps,stim_PW, flex_tl, freq, flex_ch);
    display(': Flex');
    %Stim Extensor Muscles
    ext_amps = [1 1.5]; %ma
    ext_tl = 667; %ms
    ext_ch = [3 9;4 10];
    bipolar_stim_cont(ws, ext_amps,stim_PW, ext_tl, freq, ext_ch); 
    display(': Ext');
end

ws.set_Run(ws.run_stop, 1:16);

end

function [ output_args ] = bipolar_stim_cont(ws, stim_amp, stim_PW, tl, freq, channels)

ch_list         = 1:16;
stim_PW         = 1000*stim_PW;     % Pulse width converted
if length(stim_amp) == 1
    stim_amp    = repmat(1000*stim_amp,1,size(channels,2));
else
    stim_amp    = 1000*stim_amp;
end
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

%% --the wireless stimulator expect a 16-channel command
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
end