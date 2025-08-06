function segment_duration(use_time, sheet, row, SAVE_CSV)

% 1- Extract duration of the segment
start_time = use_time(1);
end_time   = use_time(end);
segment_duration = (end_time - start_time) / 60;  % In minutes

% 2- Write duration in the corresponding row
if SAVE_CSV
    sheet.Range(sprintf('B%d', row)).Value = segment_duration;
end

end
