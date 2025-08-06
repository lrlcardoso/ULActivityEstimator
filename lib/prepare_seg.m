function [use_time, use_RH, use_LH, acc_time_RH, acc_RH, acc_time_LH, acc_LH] = ...
    prepare_seg(sheet, segment_name, segment_dir, row, SAVE_CSV)

% Set default outputs in case of early return
use_time = [];
use_RH = [];
use_LH = [];
acc_time_RH = [];
acc_RH = [];
acc_time_LH = [];
acc_LH = [];

% 1- Extract relevant variables from use signal file
use_file = fullfile(segment_dir, "UseSignal.csv");
if ~isfile(use_file)
    warning("Use signal file missing for %s", segment_name);
    return;
end
use_data = readtable(use_file, 'VariableNamingRule', 'preserve');

% Use time column and binary signals
use_RH = use_data{:, contains(use_data.Properties.VariableNames, 'RH')};
use_LH = use_data{:, contains(use_data.Properties.VariableNames, 'LH')};
use_time = use_data.Time;

% 2- Extract relevant variables from loggers files
logger1_file = fullfile(segment_dir, "Logger1.csv");
logger2_file = fullfile(segment_dir, "Logger2.csv");
if ~isfile(logger1_file) || ~isfile(logger2_file)
    warning("Logger (1 or 2) file missing for %s", segment_name);
    return;
end

logger1 = readtable(logger1_file, 'VariableNamingRule', 'preserve');  % RH
logger2 = readtable(logger2_file, 'VariableNamingRule', 'preserve');  % LH

% Time column and acc signals
acc_time_RH = logger1.("Unix Time");
acc_RH = [logger1.ax, logger1.ay, logger1.az];
acc_time_LH = logger2.("Unix Time");
acc_LH = [logger2.ax, logger2.ay, logger2.az];

% 3- Optionally write the segment name
if SAVE_CSV
    sheet.Range(sprintf('A%d', row)).Value = segment_name;
end
end
