% load data file
% choose muscles to stimulate and which animals
% define defaults (pw)
% low pass filter emgs
% define thresholds
% emg to current amp conversion
% stimulate based on current arrays
%TODO make this work for many animals


%% load data file
%load legendinfo
%load emg_array (aka emg array)
%make sure you're running this code in stim_arrays location
cd 'C:\Users\mkj605\Documents\GitHub\stim_arrays';
load('half_vl_300_halfstance.mat'); 
legendinfo = {legendinfo{1:3} legendinfo{6:end}};
emg_array = {emg_array{1:3} emg_array{6:end}};
muscles = 1:length(emg_array); %can also pick and choose muscles to implement


%define non-given parameters:
channels = [2 4 6 8 10 1 3 5 7];
pw = .2; %ms
%colors = {[204 0 0], [255 125 37], [153 84 255],  [106 212 0], [0 102 51], [0 171 205], [0 0 153], [102 0 159], [64 64 64], [255 51 153], [253 203 0]};

%% define thresholds and convert EMG to amplitude
%define in the same order as 'muscles' array
emglow_limit = .16*ones(1, length(channels)); %[.15 .13 .13 .13 .13 .13 .13 .13 .13 .13]; %get rid of low noise and co-contraction issues
emghigh_limit = 1*ones(1, length(channels)); %get rid of excessively high spikes
amplow_limit = [.6 2.3 1.6 .4 .3 1.7 1 1.6 .6]; %lowest level of stim to twitch (err on low side)
amphigh_limit = [2.5 4.5 4 1.5 2.2 4.5 4 4 2.5];  %highest level of stim to use

%check that limits are all defined

lm = length(muscles);
if lm~=length(emglow_limit) || lm~=length(emghigh_limit) || lm~=length(amplow_limit) || lm~=length(amphigh_limit) || lm~=length(channels); 
    disp(['emglow_limit: ' num2str(length(emglow_limit)) char(10) 'emghigh_limit: ' num2str(length(emghigh_limit))]);
    disp(['amplow_limit: ' num2str(length(amplow_limit)) char(10) 'amphigh_limit: ' num2str(length(amphigh_limit))]);
    error('Number of muscles does not match number of values in arrays for EMG and current thresholds; check that there is one value per muscle.')
end

clear('current_arr');

%figure; hold on;
for i=1:length(muscles)
    %cycle through each muscle we'll be stimulating, find the mean of the
    %filtered EMGs, and find the conversion to amplitude of current
    current_arr{i} = emg2amp(emg_array{muscles(i)}, emglow_limit(i), emghigh_limit(i), amplow_limit(i), amphigh_limit(i));
    %plot(current_arr{i}); 
end


%% Define parameters to be used to run the stimulation cycle (number of runs, length of runs, etc)
%TODO: figure out best stretch factor
%choose number of time
repeats = 11; %number of times to repeat the cycle
slowdown_factor = 4; %three seems to be pretty much a normal length step. Kind of.
amp_adjust = 1*ones(1, length(channels));
%amp_adjust([9]) = 1.8; %adjust the nth one in current array (1st is GS, 2nd is VL, etc)
%amp_adjust([6]) = .6; 
%amp_adjust = 1; 

if length(amp_adjust)>1 %if using an array of amplitude adjustment
    for i=1:length(current_arr)
        %plot(current_arr{i}); hold on;
        current_arr{i} = current_arr{i}*amp_adjust(i); 
    end
else
    current_arr = cellfun(@(x) x*amp_adjust, current_arr, 'UniformOutput', false);
end

hold off; 
figure(2); hold on;
for i=1:length(current_arr)
    plot(current_arr{i}, 'linewidth', 2);
end
legend(legendinfo{muscles});

stim_update = 30; stim_freq = 50; original_freq = 5000;

%% save original array (emg_array), repeats, slowdown factor, current
%adjustment, current array, muscles, and legend. Autoincrements.
filepath = 'C:\Users\mkj605\Documents\stimulation\';
dayname = datestr(now, 'yyyymmdd');
if ~exist([filepath dayname], 'dir')
    mkdir([filepath dayname]); %make a folder for the day's stimulation
end

i = 1;
while exist([filepath dayname '/' datestr(now, 'yyyymmdd') '_' num2str(i,'%03d') '.mat'], 'file')
    i=i+1;
end
save([filepath dayname '/' datestr(now, 'yyyymmdd') '_' num2str(i,'%03d') '.mat'], ...
    'muscles', 'legendinfo', 'repeats', 'slowdown_factor', 'amp_adjust', 'stim_update', 'stim_freq', 'original_freq', ...
    'emg_array', 'emglow_limit', 'emghigh_limit', 'amplow_limit', 'amphigh_limit', 'pw', 'current_arr');


%% Call stimulation based on array

pause_between = 0; 
force_data = array_stim_force(current_arr, stim_update, stim_freq, original_freq, slowdown_factor, pw, channels, repeats, legendinfo, pause_between, 'COM5');

%save force data
save([filepath dayname '/' datestr(now, 'yyyymmdd') '_' num2str(i,'%03d') '_force.mat'], 'force_data'); 

%TODO: array-based stim fxn with freq modulation

%THEN, quickly write array_stim (needs to iterate
%through stimulation with timing while loop and tic toc), also, downsample
%the current array to whatever frequency gets passed. also, this
%stimulation should take the entire matrix of current array and do each
%channel

%TODO: add TTL pulse stim to extra channel (probs channel 16)
