function newFilePath = Remove_inp_spaces(originalFilename, newFilename)
    % Check if the original file exists
    if ~isfile(originalFilename)
        error('Original file does not exist');
    end

    % Open the original file for reading
    fileID = fopen(originalFilename, 'r');

    % Check if the file was opened successfully
    if fileID == -1
        error('Original file could not be opened');
    end

    % Initialize a cell array to store the modified lines
    modifiedLines = {};

    % Read the original file line by line
    while ~feof(fileID)
        % Get the next line from the file
        line = fgetl(fileID);

        % Check if the line contains an equals sign
        if contains(line, '=')
            % Remove all spaces from the line
            line = strrep(line, ' ', '');
        end

        % Store the modified line in the cell array
        modifiedLines{end+1} = line; %#ok<*AGROW>
    end

    % Close the original file
    fclose(fileID);

    % Open the new file for writing
    fileID = fopen(newFilename, 'w');

    % Check if the file was opened successfully
    if fileID == -1
        error('New file could not be opened for writing');
    end

    % Write the modified lines to the new file
    for i = 1:length(modifiedLines)
        fprintf(fileID, '%s\n', modifiedLines{i});
    end

    % Close the new file
    fclose(fileID);

    % Output the file path to the new file
    newFilePath = fullfile(pwd, newFilename);
    %disp(['New file has been created successfully at: ', newFilePath]);
end
