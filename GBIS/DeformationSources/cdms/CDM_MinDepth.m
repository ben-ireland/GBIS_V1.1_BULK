function [minDepth, Theta]=CDM_MinDepth(X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,az)
% plotCDM
% plots the CDM geometry.
% 
% CDM: Compound Dislocation Model
% EFCS: Earth-Fixed Coordinate System
%
% INPUTS
% X0, Y0 and depth:
% Horizontal coordinates (in EFCS) and depth of the CDM centroid. The depth
% must be a positive value. X0, Y0 and depth have the same unit.
%
% omegaX, omegaY and omegaZ:
% Clockwise rotation angles about X, Y and Z axes, respectively, that 
% specify the orientation of the CDM in space. The input values must be in 
% degrees.
%
% ax, ay and az:
% Semi-axes of the CDM along the X, Y and Z axes, respectively, before
% applying the rotations. ax, ay and az have the same unit as X and Y.
%
% 
% OUTPUTS
% hp:
% Handles of the CDM patches.
% 
% 
% Example: Plot the CDM with the following parameters:
%
% X0 = 0.5; Y0 = -0.25; depth = 2.75; omegaX = 5; omegaY = -8; omegaZ = 30;
% ax = 0.4; ay = 0.45; az = 0.8;
% figure
% hp = plotCDM(X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,az);
% axis vis3d
% axis equal
% view(3)
% set(gcf,'renderer','painters')

% Reference journal article:
% Nikkhoo, M., Walter, T. R., Lundgren, P. R., Prats-Iraola, P. (2017):
% Compound dislocation models (CDMs) for volcano deformation analyses.
% Submitted to Geophysical Journal International, doi: 10.1093/gji/ggw427

% Copyright (c) 2016 Mehdi Nikkhoo
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files
% (the "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.

% I appreciate any comments or bug reports.

% Mehdi Nikkhoo
% Created: 2015.10.11
% Last modified: 2022.10.24
%
% Section 2.1, Physics of Earthquakes and Volcanoes
% Department 2, Geophysics
% Helmholtz Centre Potsdam
% German Research Centre for Geosciences (GFZ)
%
% email:
% mehdi.nikkhoo@gfz-potsdam.de
% mehdi.nikkhoo@gmail.com
%
% website:
% http://www.volcanodeformation.com
%
% Adapted to output minimum and centroid depth of the three CDM planes by Ben Ireland,
% University of Bristol, August 2025

% convert the semi-axes to axes
ax = 2*ax;
ay = 2*ay;
az = 2*az;

Rx = [1 0 0;0 cosd(omegaX) sind(omegaX);0 -sind(omegaX) cosd(omegaX)];
Ry = [cosd(omegaY) 0 -sind(omegaY);0 1 0;sind(omegaY) 0 cosd(omegaY)];
Rz = [cosd(omegaZ) sind(omegaZ) 0;-sind(omegaZ) cosd(omegaZ) 0;0 0 1];
R = Rz*Ry*Rx;

P0 = [X0 Y0 -depth]'; % The centroid

% RD_X
P1 = P0+ay*R(:,2)/2+az*R(:,3)/2;
P2 = P1-ay*R(:,2);
P3 = P2-az*R(:,3);
P4 = P1-az*R(:,3);

% RD_Y
Q1 = P0-ax*R(:,1)/2+az*R(:,3)/2;
Q2 = Q1+ax*R(:,1);
Q3 = Q2-az*R(:,3);
Q4 = Q1-az*R(:,3);

% RD_Z
R1 = P0+ax*R(:,1)/2+ay*R(:,2)/2;
R2 = R1-ax*R(:,1);
R3 = R2-ay*R(:,2);
R4 = R1-ay*R(:,2);

% midpoints
mP12 = (P1+P2)/2;
mP34 = (P3+P4)/2;
mR12 = (R1+R2)/2;
mR34 = (R3+R4)/2;
mR14 = (R1+R4)/2;
mR23 = (R2+R3)/2;

XPoints = [P1(1); P2(1); P3(1); P4(1); Q1(1); Q2(1); Q3(1); Q4(1); R1(1); R2(1); R3(1); R4(1)];
YPoints = [P1(2); P2(2); P3(2); P4(2); Q1(2); Q2(2); Q3(2); Q4(2); R1(2); R2(2); R3(2); R4(2)];
ZPoints = [P1(3); P2(3); P3(3); P4(3); Q1(3); Q2(3); Q3(3); Q4(3); R1(3); R2(3); R3(3); R4(3)];

[minDepth,Idx] = min(abs(ZPoints));
T0 = [XPoints(Idx),YPoints(Idx),minDepth];
HorzDist = sqrt(((T0(1)-P0(1))^2) + ((T0(2)-P0(2))^2));
VertDist = T0(3) - P0(3);
Theta = tand(HorzDist/VertDist);