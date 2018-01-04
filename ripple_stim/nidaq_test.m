% Reset to a known state and populate AI (takes ~330ms)
% Perhaps just use ai = daqfind and flushdata(ai,'all').
daqreset;
%     ai = analoginput('nidaq', 'Dev2');
ai = analoginput('nidaq', 'Dev1');
set(ai,'InputType', 'SingleEnded');
set(ai.Channel,'InputRange', [-10 10],'SensorRange',[-10 10],'UnitsRange',[-10 10]);

%add only enabled channels:
addchannel(ai,find(EMG_enable)-1);

% Setup trigger source as falling edge of an external ditigal signal
set(ai,'TriggerType','Manual');

% Setup sampling properties of ai object
set(ai,'SampleRate', sample_rate);
set(ai,'SamplesPerTrigger', samples_per_trigger);
set(ai,'LoggingMode', 'Memory');
pause(0.1);

start(ai);

%take one sample
trigger(ai); fopen(s);
strOUT2 = fns_stim_prog('r',active_channel_list-1);
fwrite(s,strOUT2);
fclose(s);

%data(:,:,trig) = getdata(ai);

            stop(ai);
            priorPorts = instrfind; % finds any existing Serial Ports in MATLAB
            delete(priorPorts);
