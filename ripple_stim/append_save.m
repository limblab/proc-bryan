%get name of file to save to
filename = 'test_save.mat'; 

%load variables from that file
load(filename); 

%define variables
trialday = {trialday 'trial date'}; 
trialnum = {trialnum 'trial number'}; 
lengthav = {lengthav 24.3}; 
heightav = {lengthav 12.4}; 
lengthstd = {lengthstd 5}; 
heightstd = {heightstd 3.53}; 

%now save
save(filename); 