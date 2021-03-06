bmi_params = bmi_params_defaults;

%%
rat = 'test';
task = 'walking';

%%
bmi_params.emg_list_4_dec = {'1','2','3','4','5','6'};
bmi_params.bmi_fes_stim_params.EMG_to_stim_map = [{'1','2','3','4','5','6'}; ...
                               {'1','2','3','4','5','6'}];

%%
bmi_params.n_lag = 5; % to see if this will break anything
bmi_params.n_emgs = 6;
bmi_params.n_neurons = 32; % the number of input channels
bmi_params.neuronIDs = [[1:16,33:48]',zeros(32,1)];


%%
H = ones(1+bmi_params.n_lag*bmi_params.n_neurons,bmi_params.n_emgs);
bmi_params.neuron_decoder = struct('H',H);
bmi_params.mode             = 'emg_only';
bmi_params.display_plots    = true;

%% polynomials, if wanted
% P = ones(length(3,bmi_params.emg_list_4_dec));
% bmi_params.neuron_decoder = struct('H',H,'P',P);

%% Setup bipolar
bmi_params.bmi_fes_stim_params.anode_map = [{2,4,6,8,10,12}; {1,1,1,1,1,1}];
bmi_params.bmi_fes_stim_params.cathode_map = [{1,3,5,7,9,11}; {1,1,1,1,1,1}];
bmi_params.bmi_fes_stim_params.return = 'bipolar';


%% setup monopolar
% bmi_params.bmi_fes_stim_params.anode_map = [{2,4,6,8,10,12} {1,1,1,1,1,1}];
% bmi_params.bmi_fes_stim_params.cathode_map = [{} {}];
% bmi_params.bmi_fes_stim_params.return = 'monopolar';


%% limitations of stimulation
bmi_params.bmi_fes_stim_params.EMG_min = zeros(6,1);
bmi_params.bmi_fes_stim_params.EMG_max = ones(6,1);

bmi_params.bmi_fes_stim_params.PW_min = zeros(6,1);
bmi_params.bmi_fes_stim_params.PW_max = .4*ones(6,1);

bmi_params.bmi_fes_stim_params.amplitude_min = zeros(6,1);
bmi_params.bmi_fes_stim_params.amplitude_max = 6*ones(6,1);

%% other random stuff
bmi_params.bmi_fes_stim_params.port_wireless = 'COM4';
bmi_params.bmi_fes_stim_params.task = task;
bmi_params.bmi_fes_stim_params.muscles = bmi_params.emg_list_4_dec;
bmi_params.save_data = true;
bmi_params.save_name = rat;
bmi_params.save_dir     = 'D:\Test';
bmi_params.bmi_fes_stim_params.path_cal_ws = 'C:\Users\bly0753\Documents\github';



