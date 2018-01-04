% load data file
% choose muscles to stimulate and which animals
% define defaults (pw)
% low pass filter emgs
% define thresholds
% emg to current amp conversion
% stimulate based on current arrays

%% load data file
emg_file = '/Users/mariajantz/Documents/Work/data/EMGdata.mat';
load(emg_file);
%musc_names = {'gluteus max', 'gluteus med', 'gastroc', 'vastus lat', 'biceps fem A',...
%    'biceps fem PR', 'biceps fem PC', 'tib ant', 'rect fem', 'vastus med', 'adduct mag', ...
%    'semimemb', 'gracilis R', 'gracilis C', 'semitend'};
musc_names = {'GS', 'Gmed', 'LG', 'VL', 'BFa',...
    'BFpr', 'BFpc', 'TA', 'RF', 'VM', 'AM', ...
    'SM', 'GRr', 'GRc', 'ST'};
%good and bad channels (1 is good, 0 is bad)
goodChannelsWithBaselines = [  ...
    1 ,  0 ,  0 , 0 , 1 , 1 ,  1 ,  0 , 1 , 1 , 0 , 0 , 1 , 1 , 1 ;...
    0 ,  1 ,  1 , 1 , 1 , 1 ,  1 ,  1 , 1 , 1 , 0 , 1 , 0 , 1 , 0 ;...
    1 ,  0 ,  1 , 1 , 1 , 0 ,  1 ,  1 , 1 , 1 , 0 , 0 , 1 , 1 , 0 ;...
    1 ,  0 ,  1 , 0 , 1 , 1 ,  1 ,  1 , 0 , 0 , 0 , 0 , 0 , 1 , 1 ;...
    1 ,  1 ,  1 , 0 , 1 , 1 ,  1 ,  1 , 1 , 0 , 0 , 1 , 1 , 1 , 0 ;...
    1 ,  1 ,  0 , 1 , 1 , 1 ,  1 ,  1 , 1 , 0 , 0 , 1 , 0 , 1 , 0 ;...
    1 ,  0 ,  1 , 1 , 1 , 1 ,  1 ,  1 , 1 , 1 , 0 , 1 , 0 , 1 , 1 ;...
    1 ,  0 ,  1 , 1 , 0 , 1 ,  1 ,  1 , 1 , 1 , 0 , 0 , 1 , 1 , 1 ];

animals = [1:8];
muscles = [1 4 5 6 7 8 3 9 12 15];
n = 4;
Wn = 30/(5000/2); %butter parameters (30 Hz)
colors = {[204 0 0], [255 125 37], [153 84 255],  [106 212 0], [0 102 51], [0 171 205], [0 0 153], [102 0 159], [64 64 64], [255 51 153], [253 203 0]};
mus_mean = {};
%rawCycleData{animal, step}(:, muscle)
clear('emg_array');
clear('std_array');
clear('legendinfo');
%get average of low pass filtered emgs
for i=1:length(muscles)
    %figure; hold on;
    for j=1:length(animals)
        if goodChannelsWithBaselines(animals(j), muscles(i))
            filtered = filter_emgs(rawCycleData, animals(j), muscles(i), n, Wn);
            %plot(filtered);
            mus_mean{i, j} = mean(filtered);
            %plot(mean(filtered));
            mus_std{i,j} = std(filtered);
        end
    end
end

for i=1:length(muscles) %make all the same length, then average.
    a = mus_mean(i, :);
    a = a(~cellfun('isempty', a));
    ds_mat = norm_mat(dnsamp(a).');
    clear('a');
    emg_array{i} = mean(ds_mat.');
    arr_lens(i) = length(emg_array{i});
    legendinfo{i} = musc_names{muscles(i)};
    
    %std
    %     b = mus_std(i, :);
    %     b = b(~cellfun('isempty', b));
    %     ds_mat = norm_mat(dnsamp(b).');
    %     clear('b');
    %     std_array{i} = mean(ds_mat.');
    std_array{i} = std(ds_mat.');
end

%NOTE: MUST RESIZE ALL ARRAYS TO BE THE SAME TODO
if ~all(arr_lens == arr_lens(1))
    %get min val
    min_val = min(arr_lens);
    emg_array = cellfun(@(x) x(1:min_val), emg_array, 'UniformOutput', false);
    %chop off the end of every array so they're all the same length (since
    %it's like one value) -- BUT this is still cheating
end


%% make IP array
emg_array{end+1} = mean([emg_array{1}; emg_array{6}; emg_array{10}]);
std_array{end+1} = 1.4*mean([std_array{1}; std_array{6}; std_array{10}]);
legendinfo{end+1} = 'IP';
%plot(ip_arr, 'k', 'linewidth', 2);
%add legend

%% choose only a certain segment of the array for a given muscle

%for example, RF:
%emg_array{8}(600:end) = 0;


%% Translate a muscle's curve (wrap around the end of the array)
%emg_array{1} = circshift(emg_array{1}.', 100).';


%% Add in a gaussian curve to one of the muscles
%hmm. average? kind of a weighted average? (IN ALL REGIONS where the
%y-value of the gaussian is greater than the y-value of the emg array)
% 
% %calculate the curve itself
% c = 1.5; %1/c = height of peak %2.7
% mu = 250; %mu is the x-location of the peak
% peakwidth = 150; %width from peak to intercept with emglow_limit (noise threshold)
% emglow_limit = .13; %to set omega so that the graph intercepts at the emg threshold
% omega = sqrt(-peakwidth^2/log(emglow_limit/c));
% x = linspace(0, length(emg_array{2}), length(emg_array{2})).'; %values of x
% 
% y = (1/c * exp(-((x-mu).^2)/omega^2)).';
% 
% %plot(y);
% 
% % then I can either average the two plots together
% emg_array{2} = mean([emg_array{2}; y])*1.6;

%or I can only insert the gaussian where it's greater than the original
% indices = find(emg_array{10}<y);
% emg_array{10}(indices) = y(indices);

%% Remove overlap between a set of channels
% ch1 = 6; 
% ch2 = 7; 
% indices = find(emg_array{ch1}<emg_array{ch2}); 
% emg_array{ch1}(indices) = 0; 
% indices = find(emg_array{ch2}<emg_array{ch1}); 
% emg_array{ch2}(indices) = 0; 
% 
% ch1 = 1; 
% ch2 = 3; 
% indices = find(emg_array{ch1}<emg_array{ch2}); 
% emg_array{ch1}(indices) = 0; 
% indices = find(emg_array{ch2}<emg_array{ch1}); 
% emg_array{ch2}(indices) = 0; 
% 
% ch1 = 3; 
% ch2 = 11; 
% indices = find(emg_array{ch1}<emg_array{ch2}); 
% emg_array{ch1}(indices) = 0; 
% indices = find(emg_array{ch2}<emg_array{ch1}); 
% emg_array{ch2}(indices) = 0; 
% 
% ch1 = 2; 
% ch2 = 10; 
% indices = find(emg_array{ch1}<emg_array{ch2}); 
% emg_array{ch1}(indices) = 0; 
% indices = find(emg_array{ch2}<emg_array{ch1}); 
% emg_array{ch2}(indices) = 0; 

%% "Squish" part of the array relative to the other
% scale_fact = .5; %scale the indices selected by this factor
% scale_start = 300; %indices to scale from the array as it exists
% scale_end = length(emg_array{1});
% 
% x = 1:1:(scale_end-scale_start+1);
% xq = 1/scale_fact:1/scale_fact:(scale_end-scale_start);
% 
% for i=1:length(emg_array)
%     scaled = interp1(x, emg_array{i}(scale_start:scale_end), xq);
%     emg_array{i} = [emg_array{i}(1:scale_start) scaled];
%     
% end

%% Plot

%all plots on top of each other
figure; hold on;
for i=1:size(emg_array, 2)
    plot(emg_array{i}, 'linewidth', 2, 'color', colors{i}/255);
end
legend(legendinfo);

%plotted separately in a 5x2 chart
fig = figure; 
fig.OuterPosition = [100 500 1200 525]; 

%color choices
c1 = [12 100 133]/255; %stance
c2 = [191 29 41]/255; %swing
c3 = [125 58 145]/255; %dual
c_arr = [c2; c3; c1; c1; c2; c1; c3; c1; c2; c2];

vals = [1:4 6:size(emg_array, 2)]; 
cutoff_arr = ones(size(emg_array{1}))*.16; 
xval_arr = linspace(0, 100, length(emg_array{i})); 
for i=1:size(emg_array, 2)-1
    musc = vals(i);
    subplot(2, 5, i); 
    hold on; 
    %plot the arrays, cutoff, and error
    plot(xval_arr, emg_array{musc}, 'linewidth', 3, 'color', c_arr(i, :));
    plot(xval_arr, cutoff_arr, '--', 'linewidth', 1.5, 'color', 'k'); 
    %error - do fill within 1 standard deviation
    y1 = std_array{musc}(1:length(emg_array{musc}))+emg_array{musc};
    y2 = emg_array{musc}-std_array{musc}(1:length(emg_array{musc}));
    Y = [y1 fliplr(y2)];
    X = [xvals fliplr(xvals)];
    h = fill(X, Y, c_arr(i, :));
    set(h, 'facealpha', .3);
    set(h, 'EdgeColor', 'None'); 
    
    %plot formatting
    ax = gca; 
    ax.FontSize = 16; 
    title(legendinfo{musc}); 
    xlim([0 100]); 
    ylim([0 1]);
    yticks([0 .5 1]); 
end
%can now reference a specific filtered average with mus_mean{muscle, animal}
%plot(mus_mean{1,1}); hold on;

%% Save array in format that is easily useable by call_emg_stim
nsave = true;
if nsave
usr_in = input('Save as: ', 's');
if ~strcmp(usr_in, 'n')
    disp('Saving.'); 
    p = mfilename('fullpath');
    [pathstr, name, ext] = fileparts(p);
    pathstr = [pathstr '/../..' '/../' 'stim_arrays/'];
    save([pathstr usr_in], 'legendinfo', 'emg_array');
end
end

