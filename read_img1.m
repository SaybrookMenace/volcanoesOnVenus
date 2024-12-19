function A = read_img1()
    % Define file paths
    spr_filename = 'img2.spr';
    sdt_filename = 'img2.sdt';
    
    % Read metadata from .spr file
    metadata = read_spr(spr_filename);
    width = 1024
    height = 1024
    
    % Open and read binary .sdt file
    fid = fopen(sdt_filename, 'rb');
    if fid == -1
        error('Could not open .sdt file');
    end
    
    % Read image data as unsigned 8-bit integers
    A = fread(fid, [width, height], 'uint8')';
    fclose(fid);
    
    % Display the image
    imagesc(A);           % Scale and display the image
    colormap(gray);       % Use grayscale color map
    axis image;           % Preserve aspect ratio
    title('Image 1');
end

function metadata = read_spr(filename)
    % Read metadata from .spr file and parse key-value pairs
    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open .spr file');
    end
    
    % Initialize empty metadata structure
    metadata = struct();
    
    % Read each line and parse key-value pairs
    while ~feof(fid)
        line = fgetl(fid);
        tokens = split(line, '=');
        if numel(tokens) == 2
            key = strtrim(tokens{1});
            value = str2double(tokens{2});
            metadata.(key) = value;
        end
    end
    
    fclose(fid);
end
