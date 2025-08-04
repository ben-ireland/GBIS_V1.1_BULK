function U = CervelliYangPressure(m,obs,nu)

    % Sign conventions
    m(7) = -m(7);
    m(8) = -m(8);

    % Shear modulus
    mu = 1;

    [U,~,~,~] = spheroid(m,obs,nu,mu,'Pressure');
end