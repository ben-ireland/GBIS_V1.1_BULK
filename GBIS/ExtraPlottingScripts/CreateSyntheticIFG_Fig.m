close all
clear all
% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

TS_Files = dir('/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/**/timeseries/*.nc');
a = 0;
Deformation =1;
Stratified =0;
Turbulent =1;
Wrapped =1;
Source_Type =4;
ID = 'Test';
auto_angles =1;
wavelength = 0.056;
rad2m = (wavelength./(4.*pi));

for k = 0:1:3
    MogiSize = k;
    CoherenceMask = 0;
%Extract heading, incidence, and origin values
        [Heading, Incidence] = ExtractTSGeo(TS_Files(randi(length(TS_Files))),auto_angles);
        
        while ~isequal(size(CoherenceMask), [500, 500])
            a = a+1;
            [CoherenceMask] = ExtractCoMask(TS_Files(randi(length(TS_Files))));
            if a>length(TS_Files)
                error('Mismatch in sizes')
            end
        end
        
        % Links to GACOS
        % For GACOS, add code to retrieve GACOS data here
        
    
        % INPUT PARAMETERS
            % Source_Type = 1. %Earthquakes
            Quake.Strike = 0;              %strike in degrees
            Quake.Dip = 80;                 %dip in degrees
            Quake.Rake = -90;               %rake in degrees
            Quake.Slip = 1;                 %magnitude of slip vector in metres
            Quake.Top_depth = 3;           %depth (measured vertically) to top of fault in kilometres
            Quake.Bottom_depth = 6;       %depth (measured vertically) to bottom of fault in kilometres
            Quake.Length = 2;             %fault length in kilometres
            % Source_Type = 2. Dykes
            Dyke.Strike = 180-29;              %strike in degrees [0-180]
            Dyke.Dip = 90;                  %dip in degrees (usually 90 or near 90) - not from GBIS
            Dyke.Opening = 1.9;          %magnitude of opening (perpendincular to plane) in metres
            Dyke.Mid_depth = 5.05;        %From GBIS -combine with dip angle to calc. top and bottom depth
            Dyke.Top_depth = 2;            %depth (measured vertically) to top of dyke in kilometres
            Dyke.Bottom_depth = 8.1;        %depth (measured vertically) to bottom of dyke in kilometres
            Dyke.Length = 6.1;              %dyke length in kilometres
            % Source_Type = 3. Rectangular Sills
            Sill.Strike = 0;              %strike (orientation of Length dimension) in degrees [no different]
            Sill.Dip = 0;                   %Dip in degrees (usually zero or near zero)
            Sill.Opening = 10;             %magnitude of opening (perpendincular to plane) in metres
            Sill.Depth = 5;              %depth (measured vertically) to top of dyke in kilometres
            Sill.Width = 1;                %depth (measured vertically) to bottom of dyke in kilometres
            Sill.Length = 1;               %dyke length in kilometres
            % Source_Type = 4. Magma Chamber - point pressure
            if MogiSize ==2
                %Medium
                ID = 'Medium';
                Mogi.Depth  = 5;                %Depth of Mogi Source
                Mogi.Volume = 5*10^6;               %Volume in m^3
            elseif MogiSize ==1
                %Shallow
                ID = 'Shallow';
                Mogi.Depth  = 1;
            %         Mogi.Depth  = 3.0341;                %Depth of Mogi Source
                Mogi.Volume = 2*1e5;               %Volume in m^3
            elseif MogiSize ==3
                %Large
                ID = 'Large';
                Mogi.Depth  = 5;                %Depth of Mogi Source
                Mogi.Volume = 1.5*1e7;               %Volume in m^3
            elseif MogiSize ==0
                %Small
                ID = 'Small';
                Mogi.Depth  = 5;
                Mogi.Volume = 1.5*1e6;         
            end
            % Source_Type = 5. Pressurized Penny-shaped Horizontal Crack (Fialko) - Sill
            % Note, this is the slowest to calculate of the various sources
            
            Penny.Depth  = 5;                %Depth of crack in km^3
            Penny.Pressure = 1*1e6;         %Pressure of crack in Pa
            Penny.Radius  = 5;               %Radius of crack in km^3
        
        [SynData(k+1)] = GenSynthIFGs2(Deformation, Stratified, Turbulent, Wrapped, Quake, Dyke, Sill, Mogi, Penny, Heading, Incidence, wavelength, Source_Type, k, ID, CoherenceMask); 
end

tl = tiledlayout(2,2);
tl.Padding = "tight";
c2 = rad2m*(max(abs(SynData(4).combined(:))));
        
for k = 1:4
    nexttile
    disp(SynData(k).combined)
    h = imagesc(rad2m*SynData(k).combined)
    set(h, 'AlphaData', ~isnan(SynData(k).combined))
    caxis([-c2 c2])
    colormap(cmap2.redToBlue) 
    set(gcf,'color',[0 0 0]);
    ax = gca;
    ax.XTickLabel = [];
    ax.YTickLabel = [];

    % If you want to remove ticks as well, uncomment the following lines
    ax.XTick = [];
    ax.YTick = [];
    axis square
    if k==4
        c = colorbar;
        c.Label.String = 'LOS displacement (m)';
    end
end

Fig = tl;
saveas(Fig,'CSMSynFig.png');
