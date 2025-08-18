function U = CDM_Dyke(m,obs,nu)

    X = obs(1,:);
    Y = obs(2,:);
    X0 = m(1);
    Y0 = m(2);
    depth = m(3);
    ax = m(4);
    ay = 0;
    az = m(5);
    dv = m(7);
    omegaX = 0;
    omegaY = 0;
    omegaZ = m(6);

    ax2 = 2*ax;
    ay2 = 2*ay;
    az2 = 2*az;
    opening = dv/(ax2*ay2+ax2*az2+ay2*az2);

    Warn=1;
    if Warn == 1 && ((ax>az && ax/opening< 1000) || (az>ax && az/opening< 1000) || ax/az<0.25) % ax/opening comes from Krumbholz et al. 2014 and ax/az ratio from 
        U = [zeros(size(obs,2),1)';zeros(size(obs,2),1)';zeros(size(obs,2),1)'];
    else
        [ue,un,uv,DV]=CDM(X,Y,X0,Y0,depth,omegaX,omegaY,omegaZ,ax,ay,...
        az,opening,nu);
        U = [ue';un';uv'];
    end
end