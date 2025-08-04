function RedChiSq = CalculateChiSq(OutputFilepath)

    Farfield=1;

    % Load results
    load(OutputFilepath);
    WRSS = invResults.model.OptweightedRSS;
    RSS = invResults.model.OptRSS;
    RMSE = invResults.model.OptRMSE;
    nPara = length(model.parName);

    % Load other files
    Files = dir('/scratch/Ben/GBIS_BULK/InputData/*_BB_CF_Avg_Pgon_12_4_0.5_MaskVolc_ICA_DS_BoundingBox_.mat');

    n = 0;
    for k = 1:length(Files)
        if matches(Files(k).name(1:4),inputFile.name)
            n = n+1;
            Files2(n) = Files(k);
        end
    end

    % Get weightings of invCov matrix
    for i = 1:length(insar)
        [Data, ~, Residual] = RecalculateResiduals(OutputFilepath);

        % if Farfield==1
        %     % Calculate farfield variance
        %     load(strcat(Files2(i).folder,'/',Files2(i).name))
        %     [XCoords, YCoords] = meshgrid(1:size(Img,1),1:size(Img,2));
        %     In = inpolygon(L);
        % end

        if length(insar)>1 && i>1
            Data = [Data{1}; Data{2}];
            Residual = [Residual{1}; Residual{2}];
        end
        
        if length(insar)==1
            Data = Data{i};
            Residual = Residual{i};
        end

        if length(insar)>1 && i>1 || length(insar)==1
            Variance = var(Data);
            ChiSq = sum((Residual.^2./Variance));
            RedChiSq = ChiSq/(nObs-nPara);
        end
    end
end