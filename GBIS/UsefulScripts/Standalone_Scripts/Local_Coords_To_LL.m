clear variables; clear all;

% Longonot
% LocalXY = [23988.970928621; 24519.2551685235]; % Coordinates of source
% RefPoint = [36.2403; -1.1446]; % from geo.referencePoint in relevant .inp file

% Suswa EP1
% LocalXY = [15037; 17106]; % Coordinates of source
% RefPoint = [36.196; -1.3115]; % from geo.referencePoint in relevant .inp file

% Suswa EP2
LocalXY = [17935; 16727]; % Coordinates of source
RefPoint = [36.196; -1.3115]; % from geo.referencePoint in relevant .inp file

SourceXY = local2llh(LocalXY./1000, RefPoint)