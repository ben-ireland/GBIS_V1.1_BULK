function writeStructToFile2(filename, strct)
    fields = fieldnames(strct);
    fid = fopen(filename, 'wt');
    
    for i = 1:numel(fields)
        fieldname = fields{i};
        fieldval = getStructFieldValues(strct, fieldname);
        
        if isnumeric(fieldval) && numel(fieldval) > 1
            fieldval = num2str(fieldval, '%.15g\t');
        elseif ischar(fieldval)
            fieldval = strcat('"', fieldval, '"');
        end
        
        fprintf(fid, '%s\t%s\n', fieldname, fieldval);
    end
    
    fclose(fid);
end

function val = getStructFieldValues(strct, fieldname)
    val = getfield(strct, fieldname);
    
    if isstruct(val)
        nestedfields = fieldnames(val);
        for j = 1:numel(nestedfields)
            nestedfieldname = nestedfields{j};
            nestedval = getStructFieldValues(val, nestedfieldname);
            val = setfield(val, nestedfieldname, nestedval);
        end
    end
end
