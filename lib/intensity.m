function [magnitude_RH, magnitude_LH, avg_int_RH, avg_int_LH] = intensity(use_time, use_RH, use_LH, acc_time_RH, acc_RH, acc_time_LH, acc_LH, signal_process_parms, sheet, row, SAVE_CSV, SHOW_DEBG_PLOTS)

% Prepare plot
fig = figure('Visible', 'off');

% Load parameters
[fs_imu, window, stride, low_cut, high_cut, filter_order] = signal_process_parms{:};

% Moving average setup
window_size = round(window * fs_imu);   
step_size   = round(stride * fs_imu);  

% Filter setup
[b_low, a_low] = butter(filter_order, high_cut / (fs_imu/2), 'low');
[b_high, a_high] = butter(filter_order, low_cut / (fs_imu/2), 'high');
min_seg_len = 3 * max( ...
    max(length(a_low), length(b_low)), ...
    max(length(a_high), length(b_high)) ...
);

% Load inputs
scale_factor = (2 / (2^16)) * 4;
acc_signals = cellfun(@(x) x * scale_factor, {acc_RH, acc_LH}, 'UniformOutput', false);
acc_times = {acc_time_RH, acc_time_LH};
use_signals = {use_RH, use_LH};
labels = {'RH', 'LH'};
colors = {'r', 'b'};  % red for RH, blue for LH

% Preallocate outputs
avg_int_RH = [];
avg_int_LH = [];

for s = 1:2
    acc_signal = acc_signals{s};
    acc_time = acc_times{s};
    use_signal = use_signals{s};

    % 1- Apply a band=pass filter to the imu signal (to remove noise and gravity component)
    valid_mask = ~isnan(acc_signal);
    acc_signal(isnan(acc_signal)) = 0;
    
    for col = 1:size(acc_signal, 2)
        x = acc_signal(:, col);
        mask = valid_mask(:, col);
    
        d_mask = diff([0; mask; 0]);
        start_idxs = find(d_mask == 1);
        end_idxs   = find(d_mask == -1) - 1;
    
        for i = 1:length(start_idxs)
            idx_range = start_idxs(i):end_idxs(i);
            segment = x(idx_range);
    
            if length(segment) >= min_seg_len && any(abs(segment) > 0)
                segment = filtfilt(b_low, a_low, segment);
                segment = filtfilt(b_high, a_high, segment);
            else
                segment = zeros(size(segment));  % force to zero
            end
    
            x(idx_range) = segment;
        end
        acc_signal(:, col) = x;
    end
    
    % 2- Compute the magnitude of the acceleration
    magnitude_signal = sqrt(sum(acc_signal.^2, 2));
    
    % 3- Compute the Instantaneous Intensity
    % Interpolate use_signal (fs_video) to match logger_time (fs_imu)
    use_signal_interp = interp1(use_time, use_signal, acc_time, 'nearest', 0);
    % Apply mask to keep only active periods
    mask = logical(fillmissing(use_signal_interp, 'constant', 0));
    magnitude_signal(~mask) = 0;

    % 4- Compute the average intensity signal
    n = length(magnitude_signal);

    % Compute downsampled smoothed values
    start_indices = 1:step_size:(n - window_size + 1);
    n_windows = length(start_indices);
    avg_int_down = zeros(n_windows, 1);
    time_down = zeros(n_windows, 1);

    for i = 1:n_windows
        idx_range = start_indices(i):(start_indices(i) + window_size - 1);
        if sum(use_signal_interp(idx_range), 'omitnan') ~= 0
            avg_int_down(i) = sum(magnitude_signal(idx_range), 'omitnan') / sum(use_signal_interp(idx_range), 'omitnan');
        else
            avg_int_down(i) = 0;
        end
        time_down(i) = mean(idx_range); %idx_range(end); %
    end

    % Upsample back to original sampling rate
    full_time = (1:n)';
    avg_int = interp1(time_down, avg_int_down, full_time, 'linear', 'extrap');

    % 5- Save avg signals, compute the total intensity and write to Excel
    t_min = (acc_time - acc_time(1)) / 60;
    if s == 1
        avg_int_RH = avg_int;
        magnitude_RH = magnitude_signal;
        if SAVE_CSV
            total_int_RH = trapz(t_min,avg_int);
            sheet.Range(sprintf('E%d', row)).Value = total_int_RH;
        end
    else
        avg_int_LH = avg_int;
        magnitude_LH = magnitude_signal;
        if SAVE_CSV
            total_int_LH = trapz(t_min,avg_int);
            sheet.Range(sprintf('F%d', row)).Value = total_int_LH;
        end
    end

    % Plot (will be removed later to centralize plotting)
    subplot(2,1,s);
    acc_time_plot = datetime(acc_time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Australia/Brisbane');
    plot(acc_time_plot, magnitude_signal, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.1); hold on;
    plot(acc_time_plot, avg_int, 'Color', colors{s}, 'LineWidth', 2);
    title([labels{s}]);
    ylim([0 1]);
    ylabel('Intensity (g)');
    xlabel('Time (HH:mm)');
end

if SHOW_DEBG_PLOTS
    set(fig, 'Visible', 'on');
else
    close(fig);
end

end
