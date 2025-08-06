function [avg_use_RH, avg_use_LH] = number_of_repetitions(use_time, use_RH, use_LH, signal_process_parms, sheet, row, SAVE_CSV, SHOW_DEBG_PLOTS)

% Prepare plot
fig = figure('Visible', 'off');

% Load parameters
[fs, window, stride] = signal_process_parms{:};

% Moving average setup
window_size = round(window * fs);   
step_size   = round(stride * fs);

% Load inputs
time = use_time;            
signals = {use_RH, use_LH};
labels = {'RH', 'LH'};
colors = {'r', 'b'};  % red for RH, blue for LH

% 1- Compute the number of repetitions for each side
n_rep_RH = sum(diff([0; use_RH]) == 1);
n_rep_LH = sum(diff([0; use_LH]) == 1);

% Preallocate outputs
avg_use_RH = [];
avg_use_LH = [];

% 2- Compute and plot the average use signal
for s = 1:2
    signal = signals{s};
    n = length(signal);

    % Compute downsampled smoothed values
    start_indices = 1:step_size:(n - window_size + 1);
    n_windows = length(start_indices);
    smoothed_down = zeros(n_windows, 1);
    time_down = zeros(n_windows, 1);

    for i = 1:n_windows
        idx_range = start_indices(i):(start_indices(i) + window_size - 1);
        smoothed_down(i) = mean(signal(idx_range), 'omitnan');
        time_down(i) = mean(idx_range); %idx_range(end); %
    end

    % Upsample back to original sampling rate
    full_time = (1:n)';
    avg_use = interp1(time_down, smoothed_down, full_time, 'linear', 'extrap');

    % Save output
    if s == 1
        avg_use_RH = avg_use;
    else
        avg_use_LH = avg_use;
    end

    % Plot (will be removed later to centralize plotting)
    subplot(2,1,s);
    time_plot = datetime(time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Australia/Brisbane');
    plot(time_plot, signal, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.1); hold on;
    plot(time_plot, avg_use, 'Color', colors{s}, 'LineWidth', 2);
    title([labels{s}]);
    ylim([0 2]);
    ylabel('Use Signal');
    xlabel('Time (HH:mm)');
end

% 3- Write the number of repetitions in the corresponding row and columns
if SAVE_CSV
    sheet.Range(sprintf('C%d', row)).Value = n_rep_RH;
    sheet.Range(sprintf('D%d', row)).Value = n_rep_LH;
end

if SHOW_DEBG_PLOTS
    set(fig, 'Visible', 'on');
else
    close(fig);
end

end