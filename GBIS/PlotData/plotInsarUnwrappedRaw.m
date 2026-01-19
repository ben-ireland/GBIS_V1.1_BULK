function plotInsarUnwrappedRaw(xy, los, cmap, name)

% Function to plot unwrapped InSAR data
%
% Usage: plotInsarWrapped(xy, los, cmap, name)
% Input Parameters:
%       xy: local coordinates of data points
%       los: line-of-sight displacement measured at data points
%       cmap: colormaps for plotting
%       name: name of dataset for figure title
% =========================================================================
% This function is part of the:
% Geodetic Bayesian Inversion Software (GBIS)
% Software for the Bayesian inversion of geodetic data.
% Copyright: Marco Bagnardi, 2018
%
% Email: gbis.software@gmail.com
%
% Reference: 
% Bagnardi M. & Hooper A, (2018). 
% Inversion of surface deformation data for rapid estimates of source 
% parameters and uncertainties: A Bayesian approach. Geochemistry, 
% Geophysics, Geosystems, 19. https://doi.org/10.1029/2018GC007585
%
% The function may include third party software.
% =========================================================================
% Last update: 8 August, 2018
%% Patch scattered data for faster plotting
    if length(los)>1e6
        xy = xy(1:10:end,:);
        los = los(1:10:end);
    end
    edge = round(((min(abs(diff(xy(:,3)))))+1))/2; % Size of patch set top minumum distance between points %Edited
    if edge < 50
        edge = 50;
    end
    xs = [xy(:,2)'; xy(:,2)'+edge; xy(:,2)'+edge; xy(:,2)']; % Coordinates of four vertex of patch
    ys = [xy(:,3)'; xy(:,3)'; xy(:,3)'+edge; xy(:,3)'+edge];
 
  
% Display unwrapped interferogram
    %colormap(jet)    
    colormap(cmap.redToBlue); 
    h2 = patch(xs, ys, 'r');
    set(h2, 'facevertexcdata', los, 'facecolor', 'flat', 'edgecolor', 'none')
    c = max(abs([min(los), max(los)])); % Calculate maximu value for symmetric colormap
    caxis([-c c])
    axis equal; axis tight;
    axis square;
    ax = gca;
    grid on
    ax.Layer = 'top';
    ax.Box = 'on';
    ax.LineWidth = 1.0;
    ax.GridLineStyle = '--';
    cbar = colorbar; ylabel(cbar,'Line-of-sight displacement m','FontSize', 14); 
    xlabel('X distance from local origin (m)','FontSize', 14)
    ylabel('Y distance from local origin (m)','FontSize', 14)
    t = title(['Unwrapped InSAR Data: ', name],'FontSize', 18,'Interpreter','none');
    set(t,'Position',get(t,'Position')+[0 1000 0]);
    drawnow