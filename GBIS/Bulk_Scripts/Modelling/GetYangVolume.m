function EquivVol = GetYangVolume(filename,burning)
% Ben Ireland, March 2025 - Adapted Cervelli spheroid code (details below) to extract equivalent volumes from pressures

[Per_25_Results, Per_975_Results, Optimal_Results, Mean_Results, Median_Results] = extractPercentiles(filename,burning);

% Create 8x6 matrix of percentile results (input parameters for ExtractYangVolume)
Results = [Optimal_Results; Mean_Results; Median_Results; Per_25_Results; Per_975_Results];

nu=0.25; mu=1; flag = 'pressure';
for k = 1:size(Results,1)
    for j = 1:8
        m(j-8) = Results(k,j);
    end

    m = [m(4),m(4).*m(5),m(7),m(6),m(1),m(2),m(3),m(8)];

    EquivVol(k) = ExtractYangVolume(m,nu,mu,flag);
end
end