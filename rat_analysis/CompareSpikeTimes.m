clear all
%Extract Data
filename = 'Timing10.plx';
[an_data,sp_data] = import_plexon(filename);
stim_freq = 1;
freq = an_data.freq(17);

%Find analog stim times
an_stim_t = find(abs(an_data.data(17,:))>0.1);
an_stim = [an_stim_t(1)];
for i = 2:length(an_stim_t)
    if an_stim_t(i) - an_stim(end) > 10
        an_stim(end+1) = an_stim_t(i);        
    end    
end
an_stim = an_stim/freq;

for i = [1:32]
    near_pos = knnsearch(sp_data(i).ts,an_stim');
    diff(i,:) = an_stim - sp_data(i).ts(near_pos)';
end

diff(find(abs(diff) > 1 / (2 * stim_freq))) = 0;
hist(reshape(diff,1,[]),20)
res = [mean(diff')',std(diff')'];
save('lags10.mat','res');