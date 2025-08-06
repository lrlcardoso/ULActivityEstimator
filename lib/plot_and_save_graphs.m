function [fig] = plot_and_save_graphs(use_time_RH, use_time_LH, use_RH, use_LH, avg_use_RH, avg_use_LH, ...
    acc_time_RH, acc_time_LH, magnitude_RH, magnitude_LH, ...
    avg_int_RH, avg_int_LH, avg_int_levels_RH, avg_int_levels_LH, ...
    SHOW_PLOTS, SAVE_PLOTS, plot_save_dir, file_name, varargin)

% === CONFIG ===
if isempty(varargin)
    colors = {'r', 'b', [1 0.5 0; 0.5 0.5 0.5; 0 0 0]};
    side_str =  {'RH', 'LH'};
else
    colors = varargin{1};
    side_str = varargin{2};
end

legend_handles = gobjects(1,5);  % Raw, Avg, Low, Medium, High
legend_labels  = {'Raw Detection/Intensity', 'Avg. Detection', 'Avg. Intensity', 'Low Intensity', 'Medium Intensity', 'High Intensity'};

% === PREPARE FIGURE ===
fig = figure('Visible', 'off', 'Units', 'pixels', 'Position', [360, 500, 560, 420]);
t = tiledlayout(3, 2, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% === DATA ===
times = {use_time_RH, acc_time_RH, acc_time_RH; use_time_LH, acc_time_LH, acc_time_LH};
signals = {[use_RH avg_use_RH], [magnitude_RH avg_int_RH], avg_int_levels_RH; ...
           [use_LH avg_use_LH], [magnitude_LH avg_int_LH], avg_int_levels_LH};
title_str = {'Discrete Movements', 'Intensity', 'Intensity Levels vs Time'};
label_str = {'Detection', 'Intensity (g)', '% of Time'};

% === PLOT LOOP ===
for type = 1:3  % rows (Movement, Intensity, Levels)
    for side = 1:2  % columns (RH / LH)
        nexttile(side + (type-1)*2);

        time = times{side, type};
        time_sec = time - time(1);                  % relative time in seconds
        time_plot = seconds(time_sec);              % convert to duration
        
        % Limit to first 2 minutes (120 seconds)
        mask = time_sec <= 120;
        time_plot = time_plot(mask);
        signal = signals{side, type};

        if type ~= 3
            signal_raw = signal(:,1);
            signal_avg = signal(:,2);

            h1 = plot(time_plot, signal_raw(mask), 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on;
            h2 = plot(time_plot, signal_avg(mask), 'Color', colors{type}, 'LineWidth', 2);

            if side == 1
                if type == 1
                    legend_handles(1) = h1;  % Raw
                    legend_handles(2) = h2;  % Avg
                else
                    legend_handles(3) = h2;  % Avg
                end
            end
        else
            h = area(time_plot, 100 .* signal(mask, :), 'LineStyle', 'none');
            set(gca, 'ColorOrder', colors{type});
            colormap(colors{type});
            if side == 1  % Only collect once
                for i = 1:min(3,numel(h))
                    legend_handles(i+3) = h(i);  % Low, Medium, High
                end
            end
        end

        % === AXIS SETUP ===
        title([side_str{side}, ': ', title_str{type}]);
        ylabel(label_str{type});
        xlabel('Time (mm:ss)');
        xtickformat('mm:ss');  % shows as 0:30, 1:15 etc.
        xlim([seconds(0), seconds(120)]);           % fix axis to 0–2 min
        xticks(seconds(linspace(0, 120, 4)));       % exactly 4 ticks
        % xlim([min(time_plot), max(time_plot)]);
        % xticks(linspace(min(time_plot), max(time_plot), 4));
        ax = gca;
        ax.XAxis.Label.Visible = 'on';
        ax.XAxis.Exponent = 0;
        ax.XAxis.SecondaryLabel.String = '';

        if type == 1
            ylim([0 1]);
            yticks([0 1]);
            yticklabels({'No', 'Yes'});
        elseif type == 2
            ylim([0 2]);
        else
            ylim([0 100]);
        end

        % Align y-labels
        xoff = -0.08;
        yl = get(gca, 'YLabel');
        set(yl, 'Units','normalized', 'Position',[xoff 0.5 0], 'HorizontalAlignment','center');
    end
end

% === SHARED LEGEND ===
if all(isgraphics(legend_handles))
    lgd = legend(legend_handles, legend_labels, ...
        'Orientation', 'horizontal', ...
        'Location', 'northoutside', 'NumColumns', 3);
    lgd.Layout.Tile = 'north';
    lgd.Box = "off";
end

% === SAVE OUTPUT ===
if SAVE_PLOTS
    if ~exist(plot_save_dir, 'dir')
        mkdir(plot_save_dir);
    end
    saveas(fig, fullfile(plot_save_dir, [file_name, '.fig']));
    exportgraphics(fig, fullfile(plot_save_dir, [file_name '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(plot_save_dir, [file_name '.pdf']), 'ContentType', 'vector', 'BackgroundColor','none');
end

% === DISPLAY ===
if SHOW_PLOTS
    set(fig, 'Visible', 'on');
else
    close(fig);
end
end
