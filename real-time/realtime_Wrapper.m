%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUMMARY
%
% Final goal
% Wrapper script to import live Plexon data, bin it, decode EMG from
% LFPs and spike timestamps, and stimulate.
%
% INPUTS:
%
%
% OUTPUTS:
%
%
% TIPS:
%
%
% TODO:
%   -Fix issues with PL_GetPars
%   -preallocate ts list for speed 
%
% Author(s): Bryan Yoder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Variable set-up
bin_size = 0.05; %in seconds
cur_ts = [];
cur_bin_ts = 0;

sp_bins = [];

%Set up socket for Plexon connection
s = PL_InitClient(0);
if s == 0
    disp('Unable to connect, exiting now');
    return
end
pause(0.05);

%Gets initial timestamp, will loop until it acquires 1
%TODO: Remove this and come up with better way
while 1
    [n,cur_ts] = PL_GetTS(s);   
    if n
        break;
    end
end
cur_bin_ts = bin_size * floor(cur_ts(1,4) / bin_size);

%pars = PL_GetPars(s) %Doesn't work over PlexNet
                      %Also returns incorrect adc rate sometimes? look into

b = tic
while toc(b)<5
    [n, ts] = PL_GetTS(s); %Gets
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
PL_Close(s);
s = 0;