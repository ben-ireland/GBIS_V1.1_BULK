function U = CDM_Oblate_Spheroid(m,obs,nu)

    X = obs(1,:);
    Y = obs(2,:);
    X0 = m(1);
    Y0 = m(2);
    depth = m(3);
    ax = m(4);
    ay = m(4);
    az = m(4).*m(5);
    dv = m(8);
    omegaX = m(6);
    omegaY = 0;
    omegaZ = m(7);

    ax2 = 2*ax;
    ay2 = 2*ay;
    az2 = 2*az;
    opening = dv/(ax2*ay2+ax2*az2+ay2*az2);
    
    % Constrain dv/V (based on chamber compressibility estimates for oblate sources) - See Yip et al. 2024 and Anderson and Segall (2011)
    V = ax2*ay2*az2; % Chamber volume
    dvV = dv/V;

    Warn = 1;
    if (az/depth>0.35 || dvV>1e-1) & Warn == 1
        U = [zeros(size(obs,2),1)';zeros(size(obs,2),1)';zeros(size(obs,2),1)'];
    else
        [ue,un,uv,DV]=CDM(X,Y,X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,...
        az,opening,nu);
        U = [ue';un';uv'];
    end
end