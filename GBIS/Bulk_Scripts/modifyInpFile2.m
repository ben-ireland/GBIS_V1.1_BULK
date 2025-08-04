function writeFileName = modifyInpFile2(inputFilePath, outputFilePath, searchString, oldSubstr, newSubstr, replaceFile, n)
% Opens a text file, finds a line in the text file based on the start of
% the line, changes a specific substring within the line, and saves the
% text file to a new location.
% 
% Inputs:
%   - inputFilePath: the path to the input text file
%   - outputFilePath: the path to the output text file
%   - searchString: the string at the start of the line to be modified
%   - oldSubstr: the substring to be replaced
%   - newSubstr: the substring to replace the old substring with
%   - replaceFile: 'y' = replace original text file; 'n' = create new text
%     file
%   - n: Change the nth occurence of the searchstring (optional). If left blank,
%     all occurences will be changed.
% 
% Ouputs:
%   - writeFileName: Output txt file the changes are written to.
% Example usage:
%   modifyInpFile2('C:\path\to\input\file.txt', 'C:\path\to\output\file.txt', 'geo.bb', '25', '67', 'y');
%   modifyInpFile2('C:\path\to\input\file.txt', 'C:\path\to\output\file.txt', 'geo.bb', '25', '67', 'y',1);

% Set a default value of 0 for n if it is not specified
    if isempty(n)
        n = 0;
    end

    if replaceFile == 'n' % Write to new file
        writeFileName = outputFilePath;
    elseif replaceFile == 'y' % Overwrite existing file
        writeFileName = inputFilePath;
    end

    % Open the input file for reading
    fid = fopen(inputFilePath, 'r');

    occurrenceCount = 0;
    lineNumber = 1;
    % Read each line of the input file
    while ~feof(fid)
        line = fgetl(fid);
        fileContents{lineNumber} = line;
        if line == -1 %If the line shows the end-of-file indicator, break the loop
            break
        end

        if n==0
            % Check if the line starts with the search string
            if startsWith(line, searchString)
                % Replace the old substring with the new substring
                fileContents{lineNumber} = strrep(line, oldSubstr, newSubstr);
            end
        else
        if startsWith(line, searchString)
            % Increment the occurrence count
            occurrenceCount = occurrenceCount + 1;
            
            % Check if this is the nth occurrence to modify
            if occurrenceCount == n
                % Replace the old substring with the new substring
                fileContents{lineNumber} = strrep(line, oldSubstr, newSubstr);
            end
        end
        end
        lineNumber = lineNumber + 1;
    end

    % Close the input and output files
    fclose(fid);

    % Open the file for writing (either a new file or the same file)
    fidNew = fopen(writeFileName, 'w');
    if fidNew == -1
        error('Error opening the file for writing: %s', writeFileName);
    end

    % Write the modified contents back to the file
    for i = 1:length(fileContents)
        fprintf(fidNew, '%s\n', fileContents{i});
    end

    % Close the file after writing
    fclose(fidNew);
end
