% this script tests PL_GetAD (get A/D data, in raw A/D units) function

% NOTE1: Reading data from up to 256 A/D ("slow") channels is supported; however, 
% please make sure that you are using the latest version of Rasputin (which includes
% support for acquisition from multiple NIDAQ cards in parallel).

% NOTE 2: See PL_GetPars.m for information on how to determine the sampling
% rates for A/D channels.  Note that in a multiple NIDAQ card
% configuration, each card may acquire data at a different sampling rate.

% before using any of the PL_XXX functions
% you need to call PL_InitClient ONCE
% and use the value returned by PL_InitClient
% in all PL_XXX calls


s = PL_InitClient(0);
if s == 0
   return
end
pause(0.05);
res = zeros(1000,1);
% get A/D data and plot it
for i=1:1000
    tic;
    [n, t] = PL_GetTS(s);
    res(i) = t(end,4) - t(1,4);    
    while(toc < 0.05)
    end
end

% you need to call PL_Close(s) to close the connection
% with the Plexon server
PL_Close(s);
s = 0;

