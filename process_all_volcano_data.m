function process_all_volcano_data()
    % Directory for all input, output, and metadata files
    base_dir = 'processedImages'; % Unified directory
    output_dir = fullfile(base_dir, 'crops'); % Subdirectory for cropped images
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Output CSV file
    csv_filename = fullfile(base_dir, 'volcano_data.csv');
    data = {}; % Cell array to collect all metadata
    
    % Process all images and their corresponding .jtri files
    img_files = dir(fullfile(base_dir, 'image_*.jpg')); % Match the naming pattern
    for k = 1:numel(img_files)
        img_filename = img_files(k).name;
        img_index = sscanf(img_filename, 'image_%d.jpg'); % Extract image index
        
        % Debug: Display current file being processed
        fprintf('Processing image: %s\n', img_filename);
        
        % Read corresponding .jtri file
        jtri_filename = fullfile(base_dir, sprintf('img%d.jtri', img_index));
        if ~isfile(jtri_filename)
            fprintf('Warning: Missing .jtri file for %s\n', img_filename);
            continue;
        end
        
        % Read and parse the .jtri file
        volcanoes = read_jtri(jtri_filename);
        if isempty(volcanoes)
            fprintf('No volcano data found in %s\n', jtri_filename);
            continue;
        end
        
        % Read the image
        img = imread(fullfile(base_dir, img_filename));
        
        % Process each volcano annotation
        for v = 1:size(volcanoes, 1)
            x = volcanoes(v, 1);
            y = volcanoes(v, 2);
            radius = volcanoes(v, 3);
            likelihood = volcanoes(v, 4); % Likelihood scale (1-4)
            
            % Define bounding box
            x_min = max(1, round(x - radius));
            y_min = max(1, round(y - radius));
            x_max = min(size(img, 2), round(x + radius));
            y_max = min(size(img, 1), round(y + radius));
            
            % Crop the region
            cropped_img = img(y_min:y_max, x_min:x_max, :);
            
            % Save the cropped image
            crop_filename = fullfile(output_dir, sprintf('image_%d_volcano_%d.jpg', img_index, v));
            imwrite(cropped_img, crop_filename);
            
            % Add metadata to the table
            data{end+1, 1} = crop_filename; % Cropped image path
            data{end, 2} = img_index;      % Original image index
            data{end, 3} = likelihood;     % Likelihood
        end
    end
    
    % Save metadata to CSV
    if ~isempty(data)
        data_table = cell2table(data, 'VariableNames', {'CroppedImage', 'ImageIndex', 'Likelihood'});
        writetable(data_table, csv_filename);
        fprintf('Metadata saved to %s\n', csv_filename);
    else
        warning('No data to save. Check your inputs.');
    end
end

function volcanoes = read_jtri(jtri_file)
    % Read .jtri file and extract volcano data
    volcanoes = [];
    fid = fopen(jtri_file, 'r');
    if fid == -1
        error('Could not open .jtri file: %s', jtri_file);
    end
    
    while ~feof(fid)
        line = fgetl(fid);
        % Match CIRCLE(x, y, radius) #1 -1 $likelihood
        tokens = regexp(line, 'CIRCLE\((\d+), (\d+), ([\d.]+)\) #\d+ -1 \$(\d+)', 'tokens');
        if ~isempty(tokens)
            tokens = tokens{1};
            x = str2double(tokens{1});
            y = str2double(tokens{2});
            radius = str2double(tokens{3});
            likelihood = str2double(tokens{4});
            volcanoes(end+1, :) = [x, y, radius, likelihood]; %#ok<AGROW>
        end
    end
    
    fclose(fid);
end
