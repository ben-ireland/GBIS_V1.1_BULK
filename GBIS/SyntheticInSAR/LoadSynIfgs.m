% IFG ELEMENTS
Deformation =1;
Stratified =0;
Turbulent =1;
Wrapped =1;
wavelength = 0.056;
Source_Type = 4; %See below section for options
TurbulentN = 3; % Number of incidences of turbulent noise
auto_angles =1;
% Use timseries' to randomise the turbulent component and the incoherence
% mask combination that is used, as well as GACOS

% GEOMETRY OF THE SATELLITE AND COORDINATE SYSTEM (add Gaptime to this and mask options)
origin = [-1.4, 36.0, 1652]; % Arbitrary origin for the lat-lon coordinate system

TS_Files = dir('/Users/jl20461/Documents/BristolPhD/COMET_InSAR_Training_2022/GBIS_V1.1_Mod3/Real_Signals_EAR/**/timeseries/*.nc');
TS_Files(4) = [];
Msizes = 0:1:3;

for n = 1:length(Msizes)
    for k = 1:TurbulentN
        %Extract heading, incidence, and origin values
        [Heading, Incidence] = ExtractTSGeo(TS_Files(randi(length(TS_Files))),auto_angles);
        [CoherenceMask] = ExtractCoMask(TS_Files(randi(length(TS_Files))));
        
        % Links to GACOS
        % For GACOS, add code to retrieve GACOS data here
        
        % SOURCE TYPE
        MogiSize = Msizes(n); %0 == small, 1== shallow, 2==medium, 3==large
    
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
                Mogi.Depth  = 4.923;                %Depth of Mogi Source
                Mogi.Volume = 3.95*10^6;               %Volume in m^3
            elseif MogiSize ==1
                %Shallow
                ID = 'Shallow';
                Mogi.Depth  = 3;
            %         Mogi.Depth  = 3.0341;                %Depth of Mogi Source
                Mogi.Volume = 1.5*1e6;               %Volume in m^3
            elseif MogiSize ==3
                %Large
                ID = 'Large';
                Mogi.Depth  = 4.923;                %Depth of Mogi Source
                Mogi.Volume = 1.5*1e7;               %Volume in m^3
            elseif MogiSize ==0
                %Small
                ID = 'Small';
                Mogi.Depth  = 4.923;
                Mogi.Volume = 1.5*1e6;         
            end
            % Source_Type = 5. Pressurized Penny-shaped Horizontal Crack (Fialko) - Sill
            % Note, this is the slowest to calculate of the various sources
            
            Penny.Depth  = 5;                %Depth of crack in km^3
            Penny.Pressure = 1*1e6;         %Pressure of crack in Pa
            Penny.Radius  = 5;               %Radius of crack in km^3
        
        [unwrapped] = GenSynthIFGs(Deformation, Stratified, Turbulent, Wrapped, Quake, Dyke, Sill, Mogi, Penny, Heading, Incidence, wavelength, Source_Type, k, ID, CoherenceMask); 
    
    end
end