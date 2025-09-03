function S_sorted = SortStruct(S,fieldName)
% Sort a structure based on field name

% Extract the field values
names = {S.(fieldName)};

% Sort the field values and get sorting indices
[~, sortedIndices] = sort(names);

% Reorder the structure array
S_sorted = S(sortedIndices);
end