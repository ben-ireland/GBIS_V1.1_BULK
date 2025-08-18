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
    dv = m(10);
    ax2 = 2*ax;
    ay2 = 2*ay;
    az2 = 2*az;
    opening = dv/(ax2*ay2+ax2*az2+ay2*az2);

    [minDepth, Theta]=CDM_MinDepth(X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,az)
    VertExt = depth-minDepth;

    Warn = 1;
    if VertExt/depth>0.35 & Warn == 1
        U = [zeros(size(obs,2),1)';zeros(size(obs,2),1)';zeros(size(obs,2),1)'];
    else
        [ue,un,uv,DV]=CDM(X,Y,X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,...
        az,opening,nu);
        U = [ue';un';uv'];
    end
end