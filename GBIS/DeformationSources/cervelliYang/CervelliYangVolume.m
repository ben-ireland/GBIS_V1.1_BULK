function U = CervelliYangVolume(m,obs,nu)

    % Sign conventions
    m(7) = -m(7);
    m(8) = -m(8);

    % Shear modulus
    mu = 1;
    
    [U,~,~,~] = spheroid(m,obs,nu,mu,'volume');
end