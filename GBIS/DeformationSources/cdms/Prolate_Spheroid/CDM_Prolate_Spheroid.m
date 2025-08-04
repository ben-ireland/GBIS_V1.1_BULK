function U = CDM_Prolate_Spheroid(m,obs,nu)

    X = obs(1,:);
    Y = obs(2,:);
    X0 = m(1);
    Y0 = m(2);
    depth = m(3);
    ax = m(4).*m(5);
    ay = m(4).*m(5);
    az = m(4);
    dv = m(8);
    omegaX = m(7);
    omegaY = 0;
    omegaZ = m(6);

    ax2 = 2*ax;
    ay2 = 2*ay;
    az2 = 2*az;
    opening = dv/(ax2*ay2+ax2*az2+ay2*az2);
    
    [ue,un,uv,DV]=CDM(X,Y,X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,...
    az,opening,nu);
    
    U = [ue';un';uv'];
end