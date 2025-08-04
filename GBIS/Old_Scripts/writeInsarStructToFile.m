function writeInsarStructToFile(Struct, filename, k)
%Function to create .inp text input file for GBIS (Bagnardi and Hooper,
%2018) from a 'insar' structure.
% Written by Ben Ireland, April 2023.
%%======================================================================%%
% Inputs:
%
% Struct = input structure to be written into the .inp file
% filename = filename (with .inp extension) of the .inp file
% k = iteration number (see WriteGBISInputFile script) if using >1 insar
% dataset
%%======================================================================%%

% Open file for writing
fid = fopen(filename, 'a');
fprintf(fid, '\n');
fprintf(fid, '%%Insar data:\n');

fprintf(fid, '\n');
fprintf(fid, 'insarID = %.0f;\n', k);
fprintf(fid, '\n');

% Call getStructFieldValues to get name-value pairs for each field in the struct
field_values = getStructFieldValues(Struct);

% Loop through each name-value pair and write to file
for i = 1:length(field_values)
    if isnumeric(field_values{i}{2})
        fprintf(fid, 'insar{insarID}.%s = %.6f;\n', field_values{i}{1}, field_values{i}{2});
        fprintf(fid, '\n');
    else
        if isempty(strfind(field_values{i}{2}, '['))
            fprintf(fid, 'insar{insarID}.%s = ''%s'';\n', field_values{i}{1}, field_values{i}{2});
            fprintf(fid, '\n');
        else
            fprintf(fid, 'insar{insarID}.%s = %s;\n', field_values{i}{1}, field_values{i}{2});
            fprintf(fid, '\n');
        end
    end
end

% Close file
fclose(fid);
end

function [field_values,fields] = getStructFieldValues(s)
% Initialize cell array to store name-value pairs
field_values = {};

% Call fieldnames function to get field names for the struct
fields = fieldnames(s);

% Loop through each field and get its value
for i = 1:length(fields)
    % Get field name
    field_name = fields{i};
    
    % Check if the field is a struct itself
    if isstruct(s.(field_name))
        % If it is a struct, recursively call this function on the sub-struct
        [sub_struct_field_values, sub_struct_field_names] = getStructFieldValues(s.(field_name));
        
        % Add the sub-struct field values to the current list of field values
        for j = 1:length(sub_struct_field_names)
            sub_field_name = sub_struct_field_names{j};
            sub_field_value = sub_struct_field_values{j};
            full_field_name = sprintf('%s.%s', field_name, sub_field_name);
            field_values{end+1} = {full_field_name, sub_field_value}; %%%%
        end
   elseif isnumeric(s.(field_name)) && numel(s.(field_name)) > 1
          field_values{end+1} = ['[', sprintf('%.2f; ', s.(field_name)), sprintf('%.2f', s.(field_name)(end)), '];'];
    else
        % If it is not a struct, get its value and add the name-value pair to the list
        field_value = s.(field_name);
        field_values{end+1} = {field_name,field_value};
    end
end
end

