function [fieldValues,fieldNames] = getStructFieldValues(structure)
% Recursively gets the values of all fields in a nested structure

fieldNames = fieldnames(structure);
fieldValues = struct();

for i = 1:length(fieldNames)
    fieldValue = structure.(fieldNames{i});

    if isstruct(fieldValue)
        subFieldValues = getStructFieldValues(fieldValue);
        fieldValues.(fieldNames{i}) = subFieldValues;
    else
        fieldValues.(fieldNames{i}) = fieldValue;
    end
end

end