cd /Users/mariajantz/Documents/Work/stim_arrays
stim_file = 'standard.mat'; 
load(stim_file); 

colors = {[204 0 0], [255 125 37], [153 84 255],  [106 212 0], [0 102 51], [0 171 205], [0 0 153], [102 0 159], [64 64 64], [255 51 153], [253 203 0]};

figure; hold on; 
step_time = .5; %in seconds
orig_rate = 5000; %in hz
new_rate = 40; %in hz
update = 20; %hz
repeats = new_rate/update; %in hz
slowdown_fact = 2; 

conv = orig_rate/update/slowdown_fact; 

for i=1:size(emg_array, 2)
    %arr_len = length(emg_array{i})/conv; 
    
    calc = interp1(1:length(emg_array{i}), emg_array{i}, 1:conv:length(emg_array{i})); 
    applied = repelem(calc, repeats); 
    plot(applied, '-s', 'MarkerFaceColor', colors{i}/255, 'MarkerEdgeColor', colors{i}/255, 'color', colors{i}/255, 'LineWidth', 5); 
end

legend(legendinfo); 