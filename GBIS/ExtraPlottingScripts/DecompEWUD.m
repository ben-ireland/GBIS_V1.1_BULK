function [EW,UD,Cumulative_asc,Cumulative_dsc,ResidAsc,ResidDsc,LOS_vector,lat,lon] = DecompEWUD(Asc_File,Dsc_File)

if ~exist([pwd,'/DecomposeLOS'],'dir')
    mkdir(pwd,'DecomposeLOS')
end

addpath(genpath([pwd,'/DecomposeLOS']));

% Load tiemseries and extract last step (i.e. cumulative displacement) and 
% save
Auto_Angles = 1;
%Asc_File = '/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/olkaria_130A_09032_111110/timeseries/olkaria_130A_09032_111110.nc';
%Dsc_File = '/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/olkaria_152D_09114_131313/timeseries/olkaria_152D_09114_131313.nc';
Asc = ncread(Asc_File,'DATA');
Dsc = ncread(Dsc_File,'DATA');
lat.Asc = ncread(Asc_File,'lat');
lon.Asc = ncread(Asc_File,'lon');
lat.Dsc = ncread(Dsc_File,'lat');
lon.Dsc = ncread(Dsc_File,'lon');
Asc = permute(Asc,[2 1 3]);
Dsc = permute(Dsc,[2 1 3]);
Cumulative_asc = Asc(:,:,end);
Cumulative_dsc = Dsc(:,:,end);
Cumulative_asc(Cumulative_asc==0) = NaN;
Cumulative_dsc(Cumulative_dsc==0) = NaN;
Asc_Frame = Asc_File(end-19:end-3);
Asc_FrameNum = Asc_Frame(1:3);
if startsWith(Asc_FrameNum,'0')
    Asc_FrameNum = extractAfter(Asc_FrameNum,'0');
end
Dsc_Frame = Dsc_File(end-19:end-3);
Dsc_FrameNum = Dsc_Frame(1:3);
if startsWith(Dsc_FrameNum,'0')
    Dsc_FrameNum = extractAfter(Dsc_FrameNum,'0');
    if startsWith(Dsc_FrameNum,'0')
        Dsc_FrameNum = extractAfter(Dsc_FrameNum,'0');
    end
end

if Auto_Angles ~=1
    headAsc = 0;
    incidenceAsc = 0;
    headDsc = 0;
    incidenceDsc = 0;
else
    if exist([pwd,'/',Asc_Frame],'dir') && exist([pwd,'/',Dsc_Frame],'dir')
        load([pwd,'/',Asc_Frame,'/Data.mat']);
        load([pwd,'/',Dsc_Frame,'/Data.mat']);
    else
        dL_Asc = char(strcat('https://gws-access.jasmin.ac.uk/public/nceo_geohazards/LiCSAR_products/'...
                        ,Asc_FrameNum,'/',Asc_Frame,'/metadata/metadata.txt'));
        
        dL_Dsc = char(strcat('https://gws-access.jasmin.ac.uk/public/nceo_geohazards/LiCSAR_products/'...
                        ,Dsc_FrameNum,'/',Dsc_Frame,'/metadata/metadata.txt'));

        MetadataAsc = webread(dL_Asc);
        headAsc = extractBetween(MetadataAsc,"heading=","avg");
        headAsc = strtrim(headAsc);
        headAsc = str2double(headAsc);
        incidenceAsc = extractBetween(MetadataAsc,"avg_incidence_angle=","azimuth");
        incidenceAsc = strtrim(incidenceAsc);
        incidenceAsc = str2double(incidenceAsc);

        MetadataDsc = webread(dL_Dsc);
        headDsc = extractBetween(MetadataDsc,"heading=","avg");
        headDsc = strtrim(headDsc);
        headDsc = str2double(headDsc);
        incidenceDsc = extractBetween(MetadataDsc,"avg_incidence_angle=","azimuth");
        incidenceDsc = strtrim(incidenceDsc);
        incidenceDsc = str2double(incidenceDsc);
    end
end

if ~exist([pwd,'/DecomposeLOS/',Asc_Frame],'dir')
    mkdir([pwd,'/DecomposeLOS'],Asc_Frame)
    addpath(genpath([pwd,'/DecomposeLOS']))
end

if ~exist([pwd,'/DecomposeLOS/',Dsc_Frame],'dir')
    mkdir([pwd,'/DecomposeLOS'],Dsc_Frame)
    addpath(genpath([pwd,'/DecomposeLOS']))
end

save([pwd,'/DecomposeLOS/',Asc_Frame,'/Data.mat'],"incidenceAsc","headAsc");
save([pwd,'/DecomposeLOS/',Dsc_Frame,'/Data.mat'],"incidenceDsc","headDsc");

% Extract frame, heading and incidence angles from LiCSAR and save

% Reshape into the correct dimensions for d = Gm 

% Calculate the look vectors from satellite geometry
LOS_asc = [-sind(incidenceAsc)*cosd(headAsc), cosd(incidenceAsc)]; % EW, UD
LOS_desc = [-sind(incidenceDsc)*cosd(headDsc), cosd(incidenceDsc)]; % EW, UD
LOS_vector = [LOS_asc;LOS_desc];
 
% Do a least squares inversion in the form m = (G'G)^-1 * G'd
% Assumes the Asc and Dsc data are on the same grid and do not need
% regridding

%For each pixel, do a (simple) inversion. I loop through each pixel, but there might be a better way to do it
G = LOS_vector;
UD = NaN(size(Cumulative_dsc)); EW=UD;
for i = 1:size(Cumulative_dsc,1)
    for j = 1:size(Cumulative_dsc,2)
        if (isnan(Cumulative_asc(i,j)) + isnan(Cumulative_dsc(i,j)))==0
            d = [Cumulative_asc(i,j); Cumulative_dsc(i,j)];
            %m(i,j,:) = (inv(transpose(LOS_vector)*LOS_vector)) * transpose(LOS_vector) * data;
            m = (G'*G)^(-1) * G'*d;
            % m(1) = UD disp at (i,j)
            % m(2) = EW disp at (i,j)
            UD(i,j) = m(2);
            EW(i,j) = m(1);
        end
    end
end

ResidAsc = Cumulative_asc - (UD + EW);
ResidDsc = Cumulative_dsc - (UD + EW);
end