function FineBoundingBoxLL = convertFineBBcoordsStep6(FineBoundingBox,FullLat,FullLon)
    % Ben Ireland, July 2025
    % Coverts Boundingbox coords (in relative idx coords) to LL based on input data

    % Create a grid of X and Y coordinates
    [xv, yv] = boundary(FineBoundingBox);
    [Xgrid, Ygrid] = meshgrid(1:size(FullLat,1), 1:size(FullLat,2));

    % Interpolate latitude and longitude at each vertex
    latVertices = interp2(Xgrid, Ygrid, FullLat, xv, yv);
    lonVertices = interp2(Xgrid, Ygrid, FullLon, xv, yv);

    FineBoundingBoxLL = polyshape(lonVertices, latVertices); 
end