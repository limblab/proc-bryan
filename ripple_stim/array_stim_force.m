function force_data = array_stim_force(current_array, sending_freq, stim_freq, sampled_freq, stretch_factor, pw, channels, repeats, muscle_names, pause_time, com_port)
%current_array should be in the form of a matrix of arrays that each have
%averaged, filtered EMG data to be sent to the corresponding channel
%pw: in ms, freqs: in hz, currents in current_array: in mA (mA and ms will
%be converted to us and uA)
%sending_freq is the rate at which I should send it to the
%stimulator--assume 20, usually
%stim_freq is the freq I should set the stimulator to (usually 30-40)
%sampled_freq is the freq at which the original current array is sampled.

%get conversion factor for xq from frequency value (hz)
%TODO: deal with losing resolution - say, a spike at the end doesn't
%necessarily show up

colors = {[204 0 0], [255 125 37], [153 84 255],  [106 212 0], [0 102 51], [0 171 205], [0 0 153], [102 0 159], [64 64 64], [255 51 153], [253 203 0]};

for i=1:size(current_array, 2)
    conv_fact = stretch_factor*sending_freq; %this will lead to a slight "stretching" effect of the step over time
    x = 1/sampled_freq:1/sampled_freq:length(current_array{i})/sampled_freq;
    xq = 1/conv_fact:1/conv_fact:length(current_array{i})/sampled_freq;
    ds_array{i} = interp1(x, current_array{i}, xq);
    %hold on;
    %figure(1); hold on;
    %plot(x, current_array{i})
    %figure(2); hold on;
    %plot(xq, ds_array{i}, 'color', colors{i}/255, 'linewidth', 2.5);
    %disp(length(ds_array{i})); %NOTE: if these aren't all the same length it'll be a nuisance
end
%TODO: figure out a way to plot this so it shows the intermediate points
%(so if it's stimulating at 40Hz, and the sample is assumed to be at 100
%hz, it shows the point in between. wait. uhm.)
%

%
% %plotting info
% for i=1:size(ds_array, 2)
%     temp{i} = repmat(ds_array{i}',1, 2)';
%     temp{i} = temp{i}(:)'
%     %hold on;
%     %plot(temp{i}, 'color', colors{i}/255, 'linewidth', 2.5);
% end
% %aleg = legend(muscle_names);
% %set(aleg,'FontSize',18);

length_stim = size(ds_array{1}, 2)/sending_freq; %gets the number of seconds being spent stimulating
totaltime = length_stim*repeats+pause_time*(repeats-1); 
disp(['Stimulating ' num2str(length_stim) ' s per step and ' num2str(totaltime) ' s total']);


%if the stimulator object doesn't exist yet, set it up:
if ~exist('ws', 'var')
    %ws = wireless_stim(com_port, 1); %the number has to do with verbosity of running feedback
    %ws.init(1, ws.comm_timeout_disable);
    
    ws_struct = struct(...
        'serial_string', com_port,...
        'dbg_lvl', 1, ...
        'comm_timeout_ms', 100, ... %-1 for no timeout
        'blocking', false, ... %change this
        'zb_ch_page', 5 ...%change this
        );
    
    ws = wireless_stim(ws_struct);
    ws.init();
end

%set up object to control force collection
f = ForceCollect; 
f.init(); 
%set duration of force collection to total time of stimulation plus 4 seconds
f.set_samples((totaltime + 4) * f.sample_rate)


%set train delay so I have staggered pulses
for i=1:length(channels)
    ws.set_TD(50+500*i, channels(i));
end

ws.set_Run(ws.run_stop, channels);

%TODO: check this
%send timing pulse
command{1} = struct('CathDur', 1000, ...    % us
    'AnodDur', 1000, ...    % us
    'CathAmp', 2000+32768, ... %uA
    'AnodAmp', 32768-2000, ... %uA
    'TL', 10, ... %ms
    'Freq', 1, ... %Hz
    'Run', ws.run_once ...
    );
ws.set_stim(command, 16);
ws.set_Run(ws.run_once_go)


%set constant parameters for stimulator
command{1} = struct('Freq', stim_freq, ...        % Hz
    'CathDur', pw*1000, ...    % us
    'AnodDur', pw*1000 ...    % us
    ); %kind of strange to put this here, need to define the amps to all be zero first TODO

if length(channels)>7
    ws.set_stim(command, channels(1:6));
    ws.set_stim(command, channels(7:end));
else
    ws.set_stim(command, channels);
end

ws.set_Run(ws.run_cont, channels);

%stimulate at appropriate channels in loop
%now that this is converted to an array of only the values I'll be sending,
%I need to actually stimulate! using a while loop with tic and toc ugh.
f.start();
b = tic; 
pause(0.5);

%make arrays to send
ds_mat = cell2mat(ds_array');

full_cmd = zeros(16, size(ds_mat, 2)); 
full_cmd(channels, :) = ds_mat;

cmd_cath = full_cmd*1000+32768; 
cmd_an = 32768-full_cmd*1000; 
%imagesc(cmd_cath) to see stim channels quickly

for steps=1:repeats %take as many steps as is specified
    disp('step'); 

    %add pause if desired
    if pause_time>0
        ws.set_Run(ws.run_stop, channels);
        pause(pause_time);
        ws.set_Run(ws.run_cont, channels);
    end

    for i=1:length(ds_array{1})%for every data point
        disp(['data pt ' num2str(i)]); 
        val = tic; 

        command{1} = struct('CathAmp', cmd_cath(:, i),... %in uA
            'AnodAmp', cmd_an(:, i));
        ws.set_stim(command, 1:16); %send updated amplitude to stimulator
        
        if toc(val)>(1/sending_freq)
            disp('too slow'); 
        end
        
        while toc(val)<(1/sending_freq)
            %do nothing
        end
        %timearray(i) = toc(a);
    end
end

%stop all stimulation before ending program
ws.set_Run(ws.run_stop, channels);

pause(4);
force_data = f.stop(); 
toc(b); 

end
