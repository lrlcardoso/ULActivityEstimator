function [avg_int_levels_RH, avg_int_levels_LH] = intensity_levels(magnitude_RH, magnitude_LH, use_time, use_RH, use_LH, acc_time_RH, avg_int_RH, acc_time_LH, avg_int_LH, signal_process_parms, limits, sheet, row, SAVE_CSV, SHOW_DEBG_PLOTS)

% Prepare plot
fig = figure('Visible', 'off');

% Load parameters
[fs_imu, window, stride] = signal_process_parms{:};
[low_lim, high_lim] = limits{:};

% Moving average setup
window_size = round(window * fs_imu);   
step_size   = round(stride * fs_imu);  

% Load inputs
magnitudes = {magnitude_RH, magnitude_LH};
int_signals = {avg_int_RH, avg_int_LH};
int_times = {acc_time_RH, acc_time_LH};
use_signals = {use_RH, use_LH};
labels = {'RH', 'LH'};

% Preallocate outputs
avg_int_levels_RH = [];
avg_int_levels_LH = [];

for s = 1:2
    magnitude = magnitudes{s};
    int_signal = int_signals{s};
    int_time = int_times{s};
    use_signal = use_signals{s};

    % 1- Compute the average intensity signal
    % Interpolate use_signal (fs_video) to match logger_time (fs_imu)
    use_signal_interp = interp1(use_time, use_signal, int_time, 'nearest', 0);

    n = length(int_signal);

    % Compute downsampled smoothed values
    start_indices = 1:step_size:(n - window_size + 1);
    n_windows = length(start_indices);
    avg_int_levels_down = zeros(n_windows, 3);
    time_down = zeros(n_windows, 1);

    for i = 1:n_windows
        idx_range = start_indices(i):(start_indices(i) + window_size - 1);
        if sum(use_signal_interp(idx_range), 'omitnan') ~= 0
            signal_window = magnitude(idx_range);
        
            % Count number of low, medium, high
            low_count = sum(signal_window <= low_lim);
            medium_count = sum(signal_window > low_lim & signal_window <= high_lim);
            high_count = sum(signal_window > high_lim);

            % Convert counts to percentages
            total_count = length(signal_window);
            low = low_count / total_count;
            medium = medium_count / total_count;
            high = high_count / total_count;
        
            avg_int_levels_down(i,:) = [low, medium, high];
        else
            avg_int_levels_down(i,:) = [0, 0, 0];
        end
        time_down(i) = idx_range(end); %mean(idx_range)
    end

    % Upsample back to original sampling rate
    full_time = (1:n)';
    avg_int_levels = interp1(time_down, avg_int_levels_down, full_time, 'linear', 'extrap');

    % 2- Save avg signals, compute the total intensity and write to Excel
    t_min = (int_time - int_time(1)) / 60;
    if s == 1
        avg_int_levels_RH = avg_int_levels;
        if SAVE_CSV
            total_int_levels_RH = trapz(t_min,avg_int_levels);
            sheet.Range(sprintf('G%d', row)).Value = total_int_levels_RH(1); % low
            sheet.Range(sprintf('H%d', row)).Value = total_int_levels_RH(2); % medium
            sheet.Range(sprintf('I%d', row)).Value = total_int_levels_RH(3); % high
        end
    else
        avg_int_levels_LH = avg_int_levels;
        if SAVE_CSV
            total_int_levels_LH = trapz(t_min,avg_int_levels);
            sheet.Range(sprintf('J%d', row)).Value = total_int_levels_LH(1); % low
            sheet.Range(sprintf('K%d', row)).Value = total_int_levels_LH(2); % medium
            sheet.Range(sprintf('L%d', row)).Value = total_int_levels_LH(3); % high
        end
    end
    
    subplot(2,1,s);
    int_time_plot = datetime(int_time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Australia/Brisbane');
    area(int_time_plot, avg_int_levels, 'LineStyle', 'none');
    ylim([0 2]);
    ylabel('Proportion of Time');
    xlabel('Time (HH:mm)');
    title([labels{s}, ': Intensity type vs. time']);
    set(gca, 'ColorOrder', [1 0.5 0; 0.5 0.5 0.5; 0 0 0]);
    colormap([1 0.5 0; 0.5 0.5 0.5; 0 0 0]);
    legend({'Low', 'Medium', 'High'}, 'Location', 'northeast');

end

if SHOW_DEBG_PLOTS
    set(fig, 'Visible', 'on');
else
    close(fig);
end

end
