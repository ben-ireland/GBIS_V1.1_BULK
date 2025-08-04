function FineBoundingBoxLL = convertFineBBcoords(FineBoundingBox,Filename)
    % Ben Ireland, July 2025
    % Coverts Boundingbox coords (in relative idx coords) to LL based on input data

    load(Filename);
    
    % Create a grid of X and Y coordinates
    [xv, yv] = boundary(FineBoundingBox);
    [Xgrid, Ygrid] = meshgrid(1:size(FullResLat,1), 1:size(FullResLat,2));

    % Interpolate latitude and longitude at each vertex
    latVertices = interp2(Xgrid, Ygrid, FullResLat, xv, yv);
    lonVertices = interp2(Xgrid, Ygrid, FullResLon, xv, yv);

    FineBoundingBoxLL = polyshape(lonVertices, latVertices); 
end