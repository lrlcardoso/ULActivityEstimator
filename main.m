% =========================================================================
% Title:          UL Activity Estimator Pipeline (Main Script)
% Description:    Computes and saves upper limb use and intensity metrics
%                 from video and IMU data per segment, including:
%                   - Excel summary tables (per patient/session)
%                   - CSV files (per segment/side)
%                   - Plots (saved as .fig and .png)
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-11
% Version:        1.0
% =========================================================================
% Usage:
%   Adjust SELECTED_PATIENTS, SELECTED_SESSIONS, and SELECTED_SEGMENTS.
%   Run from MATLAB: >> main
%
% Dependencies:
%   - MATLAB R2023a or later
%   - natsort (in ./lib)
%   - Custom functions:
%       * create_patient_sheet
%       * prepare_seg
%       * segment_duration
%       * number_of_repetitions
%       * intensity
%       * intensity_levels
%       * plot_and_save_graphs
%
% Notes:
%   - If SELECTED_SEGMENTS is empty, all segments will be processed.
%   - Results are saved to SAVE_DIR in both visual and tabular formats.
%
% Changelog:
%   - v1.0: [2025-07-11] Initial implementation.
% =========================================================================

addpath('./lib');
clc; clear; close all;

% =========================================================================
% Configuration Parameters
% =========================================================================
fs_video     = 30;
fs_imu       = 100;
window       = 3;
stride       = 1;
low_cut      = 0.5;
high_cut     = 5.0;
filter_order = 2;
low_lim      = 0.1;
high_lim     = 0.25;

SHOW_PLOTS      = true;
SHOW_DEBG_PLOTS = false;
SAVE_PLOTS      = false;
SAVE_CSV        = false;

ROOT_DIR     = "C:\Users\s4659771\Documents\MyTurn_Project\Data";
LOAD_FOLDER  = "ReadyToAnalyse";
SAVE_FOLDER  = "Analysed";
SELECTED_PATIENTS = ["P02"];
SELECTED_SESSIONS = ["Session1"];
SELECTED_SEGMENTS = ["CT_7"]; %["Beat Saber_1"]; %

% =========================================================================
% Main Processing Loop
% =========================================================================
for p = 1:numel(SELECTED_PATIENTS)
    patient_id = SELECTED_PATIENTS(p);
    fprintf("Processing Patient: %s\n", patient_id);

    sheet = [];
    excel = [];
    workbook = [];

    % Ensure Excel sheet exists
    if SAVE_CSV
        summary_analysis_file = fullfile(ROOT_DIR, SAVE_FOLDER, "UpperLimbActivity_Summary.xlsx");
        [~, sheet_names] = xlsfinfo(summary_analysis_file);
        if ~ismember(patient_id, sheet_names)
            create_patient_sheet(summary_analysis_file, patient_id);
        end

        try
            excel = actxserver('Excel.Application');
            excel.Visible = false;
            workbook = excel.Workbooks.Open(summary_analysis_file);
            sheet = workbook.Sheets.Item(patient_id);
        catch ME
            warning(ME.identifier, 'Failed to open Excel: %s', ME.message);
            SAVE_CSV = false;
        end
    end

    try
        patient_dir = fullfile(ROOT_DIR, LOAD_FOLDER, patient_id);
        session_folders = dir(patient_dir);
        session_folders = session_folders([session_folders.isdir]);

        % Define session row positions
        base_rows = containers.Map({'Session1', 'Session2', 'Session3'}, [5, 27, 49]);
        next_rows = containers.Map({'Session1', 'Session2', 'Session3'}, [6, 28, 50]);

        for s = 1:numel(SELECTED_SESSIONS)
            session_key = SELECTED_SESSIONS(s);
            if SAVE_CSV && ~isKey(base_rows, session_key)
                warning("Unknown session: %s", session_key);
                continue;
            end

            matching_sessions = session_folders(startsWith({session_folders.name}, session_key));

            for ms = 1:numel(matching_sessions)
                fprintf("Session: %s\n", matching_sessions(ms).name);
                session_path = fullfile(patient_dir, matching_sessions(ms).name);

                % List segments
                if isempty(SELECTED_SEGMENTS)
                    all_segments = dir(session_path);
                    all_segments = all_segments([all_segments.isdir] & ~startsWith({all_segments.name}, '.'));
                    segment_names = natsort({all_segments.name});
                else
                    segment_names = cellstr(SELECTED_SEGMENTS);
                end

                current_row = next_rows(session_key);

                for seg = 1:numel(segment_names)
                    fprintf("Segment: %s\n", segment_names{seg});
                    segment_dir = fullfile(session_path, segment_names{seg});

                    % === Compute metrics and optionally write to Excel ===
                    [use_time, use_RH, use_LH, acc_time_RH, acc_RH, acc_time_LH, acc_LH] = ...
                        prepare_seg(sheet, segment_names{seg}, segment_dir, current_row, SAVE_CSV);

                    segment_duration(use_time, sheet, current_row, SAVE_CSV);

                    [avg_use_RH, avg_use_LH] = number_of_repetitions(...
                        use_time, use_RH, use_LH, ...
                        {fs_video, window, stride}, ...
                        sheet, current_row, SAVE_CSV, SHOW_DEBG_PLOTS);

                    [magnitude_RH, magnitude_LH, avg_int_RH, avg_int_LH] = intensity(...
                        use_time, use_RH, use_LH, ...
                        acc_time_RH, acc_RH, acc_time_LH, acc_LH, ...
                        {fs_imu, window, stride, low_cut, high_cut, filter_order}, ...
                        sheet, current_row, SAVE_CSV, SHOW_DEBG_PLOTS);

                    [avg_int_levels_RH, avg_int_levels_LH] = intensity_levels(...
                        magnitude_RH, magnitude_LH, ...
                        use_time, use_RH, use_LH, ...
                        acc_time_RH, avg_int_RH, acc_time_LH, avg_int_LH, ...
                        {fs_imu, window, stride}, {low_lim, high_lim}, ...
                        sheet, current_row, SAVE_CSV, SHOW_DEBG_PLOTS);

                    plot_save_dir = fullfile(ROOT_DIR, SAVE_FOLDER, patient_id, matching_sessions(ms).name, segment_names{seg}, "Plots");
                    plot_and_save_graphs(...
                        use_time, use_time, use_RH, use_LH, avg_use_RH, avg_use_LH, ...
                        acc_time_RH, acc_time_LH, ...
                        magnitude_RH, magnitude_LH, ...
                        avg_int_RH, avg_int_LH, ...
                        avg_int_levels_RH, avg_int_levels_LH, ...
                        SHOW_PLOTS, SAVE_PLOTS, plot_save_dir, 'Use_and_Intensity');

                    if SAVE_CSV
                        % === Prepare output directory ===
                        segment_save_dir = fullfile(ROOT_DIR, SAVE_FOLDER, patient_id, matching_sessions(ms).name, segment_names{seg});
                        if ~exist(segment_save_dir, 'dir')
                            mkdir(segment_save_dir);
                        end

                        pad_to_length = @(x, n) [x(:); nan(n - numel(x), 1)];

                        % Determine max length for RH
                        len_rh = max([numel(use_time), numel(acc_time_RH), ...
                                      numel(use_RH), numel(avg_use_RH), ...
                                      numel(magnitude_RH), numel(avg_int_RH), ...
                                      size(avg_int_levels_RH,1)]);

                        T_RH = table( ...
                            pad_to_length(use_time, len_rh), ...
                            pad_to_length(use_RH, len_rh), ...
                            pad_to_length(avg_use_RH, len_rh), ...
                            pad_to_length(acc_time_RH, len_rh), ...
                            pad_to_length(magnitude_RH, len_rh), ...
                            pad_to_length(avg_int_RH, len_rh), ...
                            pad_to_length(avg_int_levels_RH(:,1), len_rh), ...
                            pad_to_length(avg_int_levels_RH(:,2), len_rh), ...
                            pad_to_length(avg_int_levels_RH(:,3), len_rh), ...
                            'VariableNames', { ...
                                'UseTime', 'Use', 'AvgUse', ...
                                'AccTime', 'Magnitude', 'AvgIntensity', ...
                                'LowLevel', 'MediumLevel', 'HighLevel' ...
                            });
                        writetable(T_RH, fullfile(segment_save_dir, 'UpperLimbActivity_RH.csv'));


                        % Determine max length for LH
                        len_lh = max([numel(use_time), numel(acc_time_LH), ...
                                      numel(use_LH), numel(avg_use_LH), ...
                                      numel(magnitude_LH), numel(avg_int_LH), ...
                                      size(avg_int_levels_LH,1)]);

                        T_LH = table( ...
                            pad_to_length(use_time, len_lh), ...
                            pad_to_length(use_LH, len_lh), ...
                            pad_to_length(avg_use_LH, len_lh), ...
                            pad_to_length(acc_time_LH, len_lh), ...
                            pad_to_length(magnitude_LH, len_lh), ...
                            pad_to_length(avg_int_LH, len_lh), ...
                            pad_to_length(avg_int_levels_LH(:,1), len_lh), ...
                            pad_to_length(avg_int_levels_LH(:,2), len_lh), ...
                            pad_to_length(avg_int_levels_LH(:,3), len_lh), ...
                            'VariableNames', { ...
                                'UseTime', 'Use', 'AvgUse', ...
                                'AccTime', 'Magnitude', 'AvgIntensity', ...
                                'LowLevel', 'MediumLevel', 'HighLevel' ...
                            });
                        writetable(T_LH, fullfile(segment_save_dir, 'UpperLimbActivity_LH.csv'));
                    end


                    current_row = current_row + 1;
                    fprintf("\n");
                end
                next_rows(session_key) = current_row;
            end
        end

        % === Save and close Excel ===
        if SAVE_CSV && ~isempty(excel)
            workbook.Save();
            workbook.Close(false);
            excel.Quit();
            delete(excel);
            clear sheet workbook excel;
        end

    catch ME
        warning("Error for Patient %s: %s", patient_id, ME.message);
        if SAVE_CSV && ~isempty(excel)
            try workbook.Close(false); catch, end
            try excel.Quit(); catch, end
            try delete(excel); catch, end
            clear sheet workbook excel;
        end
    end
end