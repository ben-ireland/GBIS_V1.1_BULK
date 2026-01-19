function U = CervelliYangVolume(m,obs,nu)

    % Sign conventions
    m(7) = -m(7);
    m(8) = -m(8);

    % Shear modulus
    mu = 1;
    
    % Work out the depth of the top edge of the spheroid
    VertDist = m(1)*cosd(m(3));
    TopD = m(7) + VertDist;

    Warn = 1;
    if TopD>0 & Warn == 1
        warning('Spheroid top is above free-surface, displacement set to zero')
        U = [zeros(size(obs,2),1)';zeros(size(obs,2),1)';zeros(size(obs,2),1)'];
    else
        [U,~,~,~] = spheroid(m,obs,nu,mu,'volume');
    end
end