function U = PrepCDM(m,obs,nu)
    
    X = obs(1,:);
    Y = obs(2,:);
    X0 = m(1);
    Y0 = m(2);
    depth = m(3);
    omegaX = m(4);
    omegaY = m(5);
    omegaZ = m(6);
    ax = m(7);
    ay = m(8);
    az = m(9);
    opening = m(10);

    [ue,un,uv,DV]=CDM(X,Y,X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,...
    az,opening,nu);

    U = [ue';un';uv'];
end