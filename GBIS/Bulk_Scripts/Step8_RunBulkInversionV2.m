function OutputFilepaths = Step8_RunBulkInversionV2(InpFilePath,NumFrames,Options)

    % Set up initial arguments
    startDir = pwd;
    if NumFrames>1 
        frameArg = [1,2];
    elseif NumFrames == 1
        frameArg = 1;
    end
    
    OutputFilepaths = {}; % Initialise cell array of output files

    %% Helper function for setting up model runs
    function filepathOut = runModel(InpFile,code,desc,nRuns,seedingRuns)
        tic
        disp(['Running GBIS for ' desc])

        % Seeding runs
        if Options.SeedingRun == 1
            for k = 1:Options.SeedingMaxRuns
                InpFilePathSeed = strcat(InpFile(1:end-4),'_Seed',num2str(k),'.inp');

                if k < Options.SeedingMaxRuns
                    InpFilePathSeedNew = strcat(InpFile(1:end-4),'_Seed',num2str(k+1),'.inp');
                else
                    InpFilePathSeedNew = InpFile;
                end

                if k == 1
                    copyfile(InpFile,InpFilePathSeed);
                else
                    copyfile(InpFilePathSeed,InpFilePathSeedNew);
                end

                disp(['Seeding run ',num2str(k),' for ' desc])
                SeedFilepath = GBISrun(InpFilePathSeed,frameArg,'n',code,seedingRuns,Options.skipSimulatedAnnealing);
                cd(startDir)
                [InpFilePathSeedNew, BoundReduction] = ProcessSeedingRun(InpFilePathSeedNew,SeedFilepath,Options);

                if mean(BoundReduction) > Options.SeedingTargetReduction
                    copyfile(InpFilePathSeedNew,InpFile);
                    disp(['Mean bound reduction of ',num2str(Options.SeedingTargetReduction),' exceeded - moving on to full run'])
                    break
                end

                if k == Options.SeedingMaxRuns
                    copyfile(InpFilePathSeedNew,InpFile);
                    disp(['All ',num2str(Options.SeedingMaxRuns),' seeding runs complete'])
                    disp(['Mean bound reduction of ',num2str(Options.SeedingTargetReduction),' not reached - moving on to full run'])
                end
            end
        end
        % Full run
        filepathOut = GBISrun(InpFile,frameArg,'n',code,nRuns,Options.skipSimulatedAnnealing);
        close all
        toc
        cd(startDir)
    end

    %% Call for individual models

    % Mogi
    OutputFilepaths{end+1} = runModel(InpFilePath,'M','Mogi source',Options.nRuns,Options.SeedingnRuns);

    % Penny
    if Options.PennyComparison == 1
        codes = {'P','C','V'};
        descs = {'Penny source','Sun(1969) source (pressure)','Sun(1969) source (volume)'};
        OutputFilepaths{end+1} = runModel(InpFilePath,codes{Options.PennyType},descs{Options.PennyType},Options.nRuns,Options.SeedingnRuns);
    end

    % Sill
    if Options.SillComparison == 1
        OutputFilepaths{end+1} = runModel(InpFilePath,'S','Okada sill source',Options.nRuns,Options.SeedingnRuns);
    end

    % Yang
    if Options.YangComparison == 1
        codes = {'Y','E','R'};
        descs = {'Yang prolate spheroid','Cervelli Spheroid (Volume)','Cervelli Spheroid (Pressure)'};
        if Options.YangType < 1 || Options.YangType > 3
            error('Options.YangType can only be 1, 2, or 3')
        end
        OutputFilepaths{end+1} = runModel(InpFilePath,codes{Options.YangType},descs{Options.YangType},Options.nRuns,Options.SeedingnRuns);
    end

    % Dyke
    if Options.DykeComparison == 1
        OutputFilepaths{end+1} = runModel(InpFilePath,'D','Okada dyke',Options.nRuns,Options.SeedingnRuns);
    end

    % CDM
    if Options.CDMComparison == 1
        geomCodes = {'A','B','G','I','J','K','L','O'};
        geomDescs = {'CDM','CDM - simple sphere','CDM - sphere with plunge/trend','CDM - symmetric sill',...
                     'CDM - sill','CDM - dyke','CDM - prolate spheroid','CDM - oblate spheroid'};
        for g = Options.CDMGeometry
            OutputFilepaths{end+1} = runModel(InpFilePath,geomCodes{g},geomDescs{g},Options.nRuns,Options.SeedingnRuns);
        end
    end

    % Other
    if Options.OtherSource == 1
        OutputFilepaths{end+1} = runModel(InpFilePath,Options.OtherSourceType,strcat('other source type - ',Options.OtherSourceType),Options.nRuns,Options.SeedingnRuns);
    end
end