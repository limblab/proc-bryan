function rat_params = rat_params_defaults(rat_params)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

rat_params_defaults = struct( ...
    'path'      ,'C:\Users\limblab\Documents\Raw Data\plx_files',...
    'plx_file'  ,'N20_180712_noobstacles.plx',...
    'kin_file'  ,'18-07-12_noobstacles_noEMG.xlsx',...
    'rat'  ,'N20',...
    'date'  ,'18-07-12',...
    'viconCh'  ,16,...
);

if nargin
    bmi_params = varargin{1};
    if isfield(bmi_params,'adapt_params')
        % fill up the adapt_params substructure if present.
        bmi_params.adapt_params = adapt_params_defaults(bmi_params.adapt_params);
    end
else
    bmi_params = [];
end

% fill default BMI-FES params missing from input argument
if nargin
    if isfield(bmi_params,'bmi_fes_stim_params')
       bmi_params.bmi_fes_stim_params = bmi_fes_stim_params_defaults(bmi_params.bmi_fes_stim_params);
    end
end


all_param_names = fieldnames(bmi_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(bmi_params,all_param_names(i))
        bmi_params.(all_param_names{i}) = bmi_params_defaults.(all_param_names{i});
    end
end

end

