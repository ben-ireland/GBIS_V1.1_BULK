function U = Sun1969VolSource(m,obs,nu)
% Function adapts input and output to use sun69.m forward model

% Assign values in m to model parameters
x0 = m(1);
y0 = m(2);
z0 = m(3);
DV = m(5);
a = m(4);

% Assign obs to x and y
x = obs(1,:);
y = obs(2,:);

xDist = x-x0;
yDist = y-y0;

%r = sqrt((xDist).^2 + (yDist).^2); % Get radial distances from XY coordinates
[th,rho] = cart2pol(xDist,yDist); % Convert cartesian coordinates to polar coordinates
[ur,uz] = sun69(rho,z0,a,DV);
[ux,uy] = pol2cart(th,ur); % Convert polar coordinates back to cartesian coordinates
U = [ux;uy;uz;];

% Convert radial distances to NS/EW components

% Use ratio of x-x0 and y-y0 to work out the ratio of EW vs NS motion using
% the angle of the vector
% Assign signs based on convention that south and east are both +ive
% bDeg = atand(abs(x-x0)/abs(y-y0));
% xComp = bDeg/90;
% ux = xComp.*ur;
% uy = ur - ux;
% ux(xDist>0) = -ux;
% uy(yDist<0) = -uy;

% To plot and test (don't try to run this full script with the below lines
% uncommented)
% m = [25000, 25000, 4000, 1000, 1e2];
% lims = [-100000:1000:100000;-100000:1000:100000];
% [g1, g2] = meshgrid(lims(1,:),lims(2,:));
% obs(1,:) = reshape(g1,1,[]);
% obs(2,:) = reshape(g2,1,[]);
% nu = 0.25;
% U = Sun1969Source(m,obs,nu);
% scatter(obs(1,:),obs(2,:),[],U(1,:));