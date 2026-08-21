clear variables; clear all;

% Longonot
% LocalXY = [23988.970928621; 24519.2551685235]; % Coordinates of source
% RefPoint = [36.2403; -1.1446]; % from geo.referencePoint in relevant .inp file

% Suswa EP1
% LocalXY = [17500; 18157];% Coordinates of source
% RefPoint = [36.196; -1.3115]; % from geo.referencePoint in relevant .inp file

% Suswa EP2
% LocalXY = [17449; 17634]; % Coordinates of source
% RefPoint = [36.196; -1.3115]; % from geo.referencePoint in relevant .inp file

% Longonot S1
%LocalXY = [19702.2689854845; 19540.9768298922]; % CDMO
LocalXY = [19098.9212667105;	20039.4047210067]; % Mogi
RefPoint = [36.2760;-1.087];


SourceXY = local2llh(LocalXY./1000, RefPoint);