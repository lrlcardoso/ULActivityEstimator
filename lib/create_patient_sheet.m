function create_patient_sheet(SAVE_FILE, patient_id)

    % Load side_info.txt that contains the participant's impaired side
    side_info_file = "C:\Users\s4659771\Documents\MyTurn_Project\Data\Processed\side_info.txt";
    fid = fopen(side_info_file);
    side_data = textscan(fid, '%s %s', 'Delimiter', '\t');
    fclose(fid);
    patient_ids = side_data{1};
    side_letters = side_data{2};

    % Get impairment side
    imp_side = "";
    match_idx = find(strcmp(patient_ids, patient_id), 1);
    if ~isempty(match_idx)
        imp_side = side_letters{match_idx};
    else
        warning("No impairment side found for %s", patient_id);
    end

    % Load side_info.txt that contains the participant's impaired side
    imp_info_file = "C:\Users\s4659771\Documents\MyTurn_Project\Data\Processed\imp_info.txt";
    fid = fopen(imp_info_file);
    imp_data = textscan(fid, '%s %s', 'Delimiter', '\t');
    fclose(fid);
    patient_ids = imp_data{1};
    imps = imp_data{2};

    % Get impairment level
    imp_level = NaN;
    match_idx = find(strcmp(patient_ids, patient_id), 1);
    if ~isempty(match_idx)
        imp_level_str = imps{match_idx};
        imp_level = str2double(imp_level_str);  % ensures it's numeric
    else
        warning("No impairment level found for %s", patient_id);
    end

    % Get session duration
    % Base folder
    base_dir = fullfile("C:\Users\s4659771\Documents\MyTurn_Project\Data\Processed", patient_id);
    duration_minutes = NaN(3,1);  % Preallocate output for 3 sessions
    
    % Loop through Session1, Session2, Session3
    for s = 1:3
        session_tag = sprintf('Session%d', s);
    
        % Find session folder
        session_folders = dir(fullfile(base_dir, ['*' session_tag '*']));
        if isempty(session_folders)
            warning('No folder found for %s (%s)', session_tag, patient_id);
            continue;
        end
        session_folder = fullfile(base_dir, session_folders(1).name);
    
        % Look for possible task folders inside "Video"
        possible_tasks = ["CT", "VR", "FMA_and_VR"];
        camera_folder = '';
        for task = possible_tasks
            test_path = fullfile(session_folder, "Video", task, "Camera1");
            if isfolder(test_path)
                camera_folder = test_path;
                break;
            end
        end
    
        if isempty(camera_folder)
            warning('No CT/VR/FMA_and_VR folder found in %s', session_folder);
            continue;
        end
    
        % Find the segmentation file
        seg_files = dir(fullfile(camera_folder, '*segmentation*.txt'));
        if isempty(seg_files)
            warning('No segmentation file in %s', camera_folder);
            continue;
        end
        segmentation_file = fullfile(camera_folder, seg_files(1).name);
    
        % Read the file
        fid = fopen(segmentation_file, 'r');
        if fid == -1
            warning('Could not open %s', segmentation_file);
            continue;
        end
    
        while ~feof(fid)
            line = fgetl(fid);
            if contains(line, "Session Duration")
                tokens = regexp(line, '\t+', 'split');
                if numel(tokens) >= 4
                    start_time_str = strtrim(tokens{2});
                    end_time_str   = strtrim(tokens{3});
                    try
                        start_dur = duration(start_time_str, 'InputFormat', 'hh:mm:ss.SSS');
                        end_dur   = duration(end_time_str,   'InputFormat', 'hh:mm:ss.SSS');
                        duration_minutes(s) = minutes(end_dur - start_dur);
                    catch
                        warning("Invalid duration format in %s (Session %d)", segmentation_file, s);
                    end
                end
                break;
            end
        end
        fclose(fid);
    end


    % Define column headers
    col_headers = {'Duration', ...
        'N_Rep_RH', 'N_Rep_LH', ...
        'Total_Int_RH', 'Total_Int_LH', ...
        'Total_Int_Low_RH', 'Total_Int_Med_RH', 'Total_Int_High_RH', ...
        'Total_Int_Low_LH', 'Total_Int_Med_LH', 'Total_Int_High_LH'};

    % Write base content with writecell (doesn't require ActiveX)
    writecell({'Imp Side'}, SAVE_FILE, 'Sheet', patient_id, 'Range', 'A1');
    writecell({'Imp Level'}, SAVE_FILE, 'Sheet', patient_id, 'Range', 'A2');
    writecell({imp_side},  SAVE_FILE, 'Sheet', patient_id, 'Range', 'B1');
    writematrix(imp_level, SAVE_FILE, 'Sheet', patient_id, 'Range', 'B2');
    writecell(col_headers, SAVE_FILE, 'Sheet', patient_id, 'Range', 'B4');
    writecell({'Session1'}, SAVE_FILE, 'Sheet', patient_id, 'Range', 'A5');
    writematrix(duration_minutes(1), SAVE_FILE, 'Sheet', patient_id, 'Range', 'B5');
    writecell({'Session2'}, SAVE_FILE, 'Sheet', patient_id, 'Range', 'A27');
    writematrix(duration_minutes(2), SAVE_FILE, 'Sheet', patient_id, 'Range', 'B27');
    writecell({'Session3'}, SAVE_FILE, 'Sheet', patient_id, 'Range', 'A49');
    writematrix(duration_minutes(3), SAVE_FILE, 'Sheet', patient_id, 'Range', 'B49');

    % Set column widths using ActiveX
    try
        excel = actxserver('Excel.Application');
        excel.Visible = false;
        workbook = excel.Workbooks.Open(SAVE_FILE);
        sheet = workbook.Sheets.Item(patient_id);

        sheet.Columns.Item('A').ColumnWidth = 22;
        for col = 'B':'L'
            sheet.Columns.Item(col).ColumnWidth = 17;
        end

        workbook.Save();
        workbook.Close(false);
        excel.Quit();
        delete(excel);
        clear sheet workbook excel
    catch ME
        warning(ME.identifier, 'Could not set column widths: %s', ME.message);
        % Force close in case of error
        try workbook.Close(false); catch, end
        try excel.Quit();         catch, end
        try delete(excel);        catch, end
        clear sheet workbook excel
    end
end