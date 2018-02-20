function [ output_args ] = bipolar_stim(amp, pw, tl, freq)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

stim_params = struct('dbg_lvl',1,'comm_timeout_ms',15,'blocking',false,'zb_ch_page',2,'serial_string','COM4');

ws  = wireless_stim(stim_params);
ws.init();
ws.version();

%channel_list = [[1] [9]];
amp = amp*1000;

chs_cmd         = 1:ws.num_channels;
        
% set train duration, stim freq and run mode 
% ToDo: check if TL and Run are necessary if we are then doing cont
ws.set_TL( tl, chs_cmd );
ws.set_Freq(freq , chs_cmd );
                                
% set pulse width to zero
ws.set_AnodDur( pw, chs_cmd );
ws.set_CathDur( pw, chs_cmd );

amp_cmd         = zeros(1,length(chs_cmd));
amp_cmd(1)      = amp;
amp_cmd(9)      = amp;

ws.set_AnodAmp( 32768-amp_cmd, chs_cmd );
ws.set_CathAmp( 32768+amp_cmd, chs_cmd );

ws.set_PL( 0, [1:8] );
ws.set_PL( 1, [9:16] );

ws.set_Run(ws.run_once);

end

