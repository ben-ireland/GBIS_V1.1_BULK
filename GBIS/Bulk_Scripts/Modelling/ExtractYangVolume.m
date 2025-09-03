function EquivVol = ExtractYangVolume(m,nu,mu,flag)
% Ben Ireland, March 2025 - Adapted Cervelli spheroid code (details below) to extract equivalent volumes from pressures
%
% spheroid  [u,D,E,S] = spheroid(m,xyz,nu,mu,[strength_type])
%
% Internal and surface deformation from a dipping spheroid in a half space.
%
% Inputs:
%   m: 8x1 vector of model parameters:
%       vertical semi-diameter (length)
%       horizontal semi-diameters (length)
%       dip (degrees)
%       strike (degrees)
%       X1 position (length)
%       X2 position (length)
%       X3 position (length)
%       strength, pressure change (force/length^2) or volume change (m^3)
%
% xyz: 3x1 vector of observation coordinates
%  nu: Poisson's ratio
%  mu: Shear modulus (force/length^2)
%
% Optional Input:
%   strength_type: Flag to denote the strength term as either pressure or
%                  volume change, taking one of two values: 'pressure' or
%                  'volume'. If omitted, strength term defaults to
%                  pressure change.
%
% If a single input, the model vector, is given, the spheroid is plotted
% and the pressure on its internal surface is calculated.  The color scale
% depicts the departure from uniformity of the surface pressure.
%
% If no inputs are given, 15 cases with different spheroid geometries and
% observation points are tested and the results summarized.
%
% Outputs:
%   u : 3x1 vector of displacements [ux; uy; uz];
%   D : 9x1 vector of the components of the deformation gradient tensor
%       [dux/dx; duy/dx; duz/dx; dux/dy; duy/dy; duz/dy; dux/dz; duy/dz; duz/dz]
%   E : 6x1 vector of strain tensor components
%       [e11; e12; e13; e22; e23; e33];
%   S : 6x1 vector of stress tensor components
%       [s11; s12; s13; s22; s23; s33];
% Notes:
%
%  (1) [X1,X2,X3] are the coordinates of the center of the spheroid.
%      X3, therefore, should always be negative.
%
%  (2) Strike is reckoned clockwise from north (0�). The spheroid
%      dips in the strike direction, with 0� being horizontal and 90�
%      being vertical.
%
%  (3) If a = b, the solution reduces to the spherical point source (aka
%      the "Mogi" or "Anderson" source.
%
%  (4) The sign convention is such that a negative pressure change produces
%      an "inflationary" pattern of deformation.
%
%  (5) Called with a single argument, the model vector, the code plots the
%      spheroid, evaluates the pressure change on the internal cavity wall,
%      and displays the departure from uniformity with a color scale.
%
% This code corrects and extends the expressions give in "Deformation From
% Inflation of a Dipping Finite Prolate Spheroid in an Elastic Half-Space as
% a Model for Volcanic Stressing", by Xue-Min Yang. Paul Davis, and James
% Dieterich, Journal of Geophysical Research, Volume 93, Number B5, pages
% 4249 - 4257, May 10, 1998. I have written the code to correct errors
% found in the original paper, to add expressions for the deformation gradient
% tensor, from which strains and stresses are derived, and to express the
% strength term as either a pressure or volume change. I have also
% eliminated singularities where possible, by evaluating the limits as dip
% goes to 90 degrees, as x2 - X2 goes to zero, and as R1 + r3bar goes to
% zero.

% Version 1.11, October 10, 2018 USGS (PFC)

% As of 2018/10/10, the function returns only the real part of the
% calculated displacements and derivatives in cases where rounding errors
% lead to a non-zero imaginary part.

if nargin == 0
    test
    return
end

a = m(1);
b = m(2);
strength = m(8);

c = sqrt(a^2 - b^2);
b2 = b^2;
C0 = 4*(1 - nu);
C3 = C0 + 1;

if a == b
    C5 = -a^3*strength/(4*mu);
    if nargin > 4
        if strcmpi(flag,'volume')
            C5 = -strength/(4*pi);
        end
    end

    if strcmpi(flag,'pressure')
        % Find equiv volume
        EquivVol = (-4*pi)*-a^3*strength/(4*mu);
    end
else

    L0 = log((a - c)/(a + c));
    d = 1/(b2*c*(2*b2 - C0*a^2)*L0 - a*c^2*(4*b2 + C0*a^2) + a*b^4*(1 + nu)*L0^2);
    a1 = d*b2*(2*c*(a^2 + 2*b2) + 3*a*b2*L0);
    b1 = d*(a^2*c*C0 + b2*(c + C3*(c + a*L0)));

    C5 = strength/(4*mu);
    if nargin > 4
        if strcmpi(flag,'volume')
            C5 = strength*3/(8*b2*pi*(-2*b1*c^3 - a1*(a*L0*(1 - 2*nu) + c*C3)));
        end
    end

    % Find equivalent volume for a pressure
    if strcmpi(flag,'pressure')
        % Find equiv volume
        EquivVol = ((strength/4*mu)*((8*b2*pi*(-2*b1*c^3 - a1*(a*L0*(1 - 2*nu) + c*C3)))))/3;
    end
end
end