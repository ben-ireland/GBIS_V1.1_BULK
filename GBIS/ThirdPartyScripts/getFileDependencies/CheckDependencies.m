clear all
close all

[fList, pList] = matlab.codetools.requiredFilesAndProducts('/home/jl20461/GBIS_BULK/GBIS_BULK_Input.m');

a = 0;
for k = 1:length(fList)
    if startsWith (fList{k},'/home/jl20461/GBIS_BULK/GBIS/Bulk_Scripts')
        a = a+1;
        disp(fList{k})
    end
end
disp(num2str(a))