function [ output_args ] = bipolar_stim_ws(amp, pw, tl, freq, ch_list)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

stim_params = struct('dbg_lvl',1,'comm_timeout_ms',15,'blocking',true,'zb_ch_page',2,'serial_string','COM5');

ws  = wireless_stim(stim_params);
ws.init();
ws.version();

ws.set_Run(ws.run_stop, ch_list);
% %channel_list = [[1] [9]];
% amp = amp*1000;
% pw = pw * 1000;
% 
% chs_cmd         = 1:ws.num_channels;
%         
% % set train duration, stim freq and run mode 
% % ToDo: check if TL and Run are necessary if we are then doing cont
% ws.set_TL( tl, chs_cmd );
% ws.set_Freq(freq , chs_cmd );
%                                 
% % set pulse width to zero
% ws.set_AnodDur( pw, chs_cmd );
% ws.set_CathDur( pw, chs_cmd );
% 
% amp_cmd         = zeros(1,length(chs_cmd));
% amp_cmd(1)      = amp;
% amp_cmd(9)      = amp;
% 
% ws.set_AnodAmp( 32768-amp_cmd, chs_cmd );
% ws.set_CathAmp( 32768+amp_cmd, chs_cmd );
% 
% ws.set_PL( 0, [1:8] );
% ws.set_PL( 1, [9:16] );

% stim_cmd{1}         = struct(   'TL',      tl );
% stim_cmd{8}         = struct(   'TL',      tl );
% stim_cmd{2}         = struct(   'Freq',    freq );
% stim_cmd{9}        = struct(   'Freq',    freq );
% stim_cmd{3}         = struct(   'CathAmp', 32768+amp*1000 );
% stim_cmd{10}        = struct(   'CathAmp', 32768+amp*1000 );
% stim_cmd{4}         = struct(   'AnodAmp', 32768-amp*1000 );
% stim_cmd{11}        = struct(   'AnodAmp', 32768-amp*1000 );
% stim_cmd{5}         = struct(   'CathDur', pw*1000 );
% stim_cmd{12}        = struct(   'CathDur', pw*1000 );
% stim_cmd{6}         = struct(   'AnodDur', pw*1000 );
% stim_cmd{13}        = struct(   'AnodDur', pw*1000 );
% %stim_cmd{7}         = struct(   'TD',      {0} );
% %stim_cmd{15}        = struct(   'TD',      {0} );
% stim_cmd{7}         = struct(   'PL',      ones(1,1) );
% stim_cmd{14}        = struct(   'PL',      zeros(1,1) );

stim_cmd{1} = struct(   'TL', tl,...
    'Freq',    freq,...
    'CathAmp', 32768+amp*1000,...    
    'AnodAmp', 32768-amp*1000,...
    'CathDur', pw*1000,...    
    'AnodDur', pw*1000,...
    'PL',      [1,0]);
% stim_cmd{2} = struct(   'TL', tl,...
%     'Freq',    freq,...    
%     'CathAmp', 32768+amp*1000,...
%     'AnodAmp', 32768-amp*1000,...    
%     'CathDur', pw*1000,...
%     'AnodDur', pw*1000,...
%     'PL',      zeros(1,1));

% for i = 1:length(ch_list) 
%     for ii = 1:length(stim_cmd)/2
%         ws.set_stim(stim_cmd(ii+(i-1)*length(stim_cmd)/2),ch_list(i));
% 	end
% end
ws.set_stim(stim_cmd(1), ch_list);
%ws.set_stim(stim_cmd(2), ch_list(2,:));

%ws.set_stim(stim_cmd,ch_list);
%for i = 1:length(ch_list)
ws.set_Run(ws.run_cont, ch_list);
%end
%tic
stim_ctrl = msgbox('Click to Stop the Stimulation','Continuous Stimulation');

while ishandle(stim_ctrl)
    ws.set_stim(stim_cmd(1), ch_list);
    %ws.set_stim(stim_cmd(2), ch_list(2,:));
    pause(.05);
end
ws.set_Run(ws.run_stop, ch_list);
%ws.set_stim(stim_cmd, ch_list);
%ws.set_Run(ws.run_once, ch_list);

end

