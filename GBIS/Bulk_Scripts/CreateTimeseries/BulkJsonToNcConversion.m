clear variables; close all;
Files = dir('/folder/*.json');
outfolder = 'outfolder';
mask = 0;

for k = 1:length(Files)
    disp(['File ',num2str(k),' out of ',num2str(length(Files))])
    file = strcat(Files(k).folder,'/',Files(k).name);
    [NC_filename, DEM_Filename] = LiCSPortalJsonToNC(file,outfolder,mask);
end