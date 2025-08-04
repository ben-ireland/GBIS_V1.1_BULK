function [InputFilePath]=WriteGBISInputFile(geo,insar,modelInput,filename)
%Function to create .inp text input file for GBIS (Bagnardi and Hooper,
%2018). 
% The .inp file will be saved in the current working directory
%
% Written by Ben Ireland, April 2023.
%%======================================================================%%
% Inputs:
%
% geo = 'geo' structure from GBIS input data
% insar = 'insar' structure from GBIS input data
% modelInput = 'modelInput' structure from GBIS input data
% filename = desired filename (no extension)
%%======================================================================%%
% Outputs:
%
% InputFilePath = full path to the saved .inp file in the local folder
% structure
%%======================================================================%%

% Open the file for writing
fid = fopen([filename,'.inp'], 'w');
filename = [filename,'.inp'];
InputFilePath = [pwd,'/',filename];

%Get date and time
datetime = datestr(now);

% Write the header comments
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% Geodetic Bayesian Inversion Software for Bulk inversions (GBIS_Bulk)\n');
fprintf(fid, '%% Software for the bulk Bayesian inversion of geodetic data.\n');
fprintf(fid, '%% Modified from GBIS V1.1 by Ben Ireland, 2023');
fprintf(fid, '%%\n');
fprintf(fid, '%% Original copyright: Marco Bagnardi, 2018\n');
fprintf(fid, '%% Original commented background and references below:');
fprintf(fid, '%%\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% Geodetic Bayesian Inversion Software (GBIS)\n');
fprintf(fid, '%% Software for the Bayesian inversion of geodetic data.\n');
fprintf(fid, '%% Copyright: Marco Bagnardi, 2018\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% Email: gbis.software@gmail.com\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% Reference:\n');
fprintf(fid, '%% Bagnardi M. & Hooper A, (2018).\n');
fprintf(fid, '%% Inversion of surface deformation data for rapid estimates of source\n');
fprintf(fid, '%% parameters and uncertainties: A Bayesian approach. Geochemistry,\n');
fprintf(fid, '%% Geophysics, Geosystems, 19. https://doi.org/10.1029/2018GC007585\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% Last update of GBIS V1.1: 8 August, 2018\n');
fprintf(fid, '\n');
fprintf(fid, '%% This input file has been generated using the WriteGBISInputFile script\n');
fprintf(fid, '%% Written by Ben Ireland, April 2023\n');
fprintf(fid, '%% This file was created on %s. \n', datetime);
fprintf(fid, '\n');
fprintf(fid, '%% =========================================================================\n');

%Write field values and name pairs for each structure
writeGeoStructToFile(geo, filename)

insarID = length(insar);

for k=1:length(insarID)
    writeInsarStructToFile(insar{insarID}, filename, k)
end

writeModelStructToFile(modelInput, filename)

% Close the file
fclose(fid);