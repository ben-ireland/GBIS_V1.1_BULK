function [Image] = IFG2GrayscalePNG(LastStep,Options)
% Ben Ireland, University of Bristol, October 2023
% Usage: Converts an interferogram (unwrapped and in radians) into a
% grayscale image normalised to 0-255 where 0 represents the lowest i.e.
% most negative LOS value in the image, or NaN values.
%
% 'LastStep' should be an m by n matrix of displacement values in radians

% Set any NaN Values to zero displacement?
LastStep(isnan(LastStep)) = 0;

% Convert from m to radians
LastStep = LastStep*4*pi/Options.WavelengthM;

% Shift and normalise values to 0-255
LastStep = LastStep - min(LastStep(:));
LastStep = (LastStep/max(LastStep(:)))*255;

% Set any NaN values to minimum value
LastStep(isnan(LastStep)) = min(LastStep(:));

Image = LastStep;