function OutputFilepaths = Step8_RunBulkInversion(InpFilePath,NumFrames,Options)

    startDir = pwd;
    if NumFrames>1
        tic
        disp('Running GBIS for Mogi source')
        if Options.SeedingRun ==1
            InpFilePathSeed = strcat(InpFilePath(1:end-4),'_Seed.inp');
            disp('Seeding run for Mogi source')
            SeedFilepath = GBISrun(InpFilePathSeed,[1,2],'n','M',(Options.SeedingnRuns),Options.skipSimulatedAnnealing);
            cd(startDir)
            InpFilePath = ProcessSeedingRun(InpFilePath,SeedFilepath,Options);
        end
        OutputFilepaths{1} = GBISrun(InpFilePath,[1,2],'n','M',(Options.nRuns),Options.skipSimulatedAnnealing);
        close all
        toc

        if Options.PennyComparison ==1
            cd(startDir)
            if Options.PennyType ==1
                disp('Running GBIS for Penny source (much slower than Mogi)')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','P',(Options.nRuns),Options.skipSimulatedAnnealing);
            elseif Options.PennyType ==2
                disp('Running GBIS for Penny source (Sun 1969 solution with pressure) slower than Mogi')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','C',(Options.nRuns),Options.skipSimulatedAnnealing);
            elseif Options.PennyType ==3
                disp('Running GBIS for Penny source (Sun 1969 solution with volume) slower than Mogi')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','V',(Options.nRuns),Options.skipSimulatedAnnealing);
            end
            close all
            toc
        end

        if Options.SillComparison ==1
            cd(startDir)
            disp('Running GBIS for Okada sill source')
            OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','S',(Options.nRuns),Options.skipSimulatedAnnealing);
        end

        if Options.YangComparison ==1
            cd(startDir)
            disp('Running GBIS for Yang prolate spheroid source')
            if Options.YangType ==1
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','Y',(Options.nRuns),Options.skipSimulatedAnnealing);
            elseif Options.YangType ==2
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','E',(Options.nRuns),Options.skipSimulatedAnnealing);
            elseif Options.YangType ==3
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','R',(Options.nRuns),Options.skipSimulatedAnnealing);
            else
                error('Options.YangType can only have values 1, 2 or 3')
            end
        end

        if Options.DykeComparison ==1
            cd(startDir)
            disp('Running GBIS for Okada dyke')
            OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','D',(Options.nRuns),Options.skipSimulatedAnnealing);
        end

        if Options.CDMComparison ==1
            if ismember(1,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','A',(Options.nRuns),Options.skipSimulatedAnnealing);
            end
            if ismember(2,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - simple sphere')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','B',(Options.nRuns),Options.skipSimulatedAnnealing);
            end
            if ismember(3,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - sphere')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','G',(Options.nRuns),Options.skipSimulatedAnnealing);   
            end             
            if ismember(4,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - symmetric sill')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','I',(Options.nRuns),Options.skipSimulatedAnnealing);
            end                
            if ismember(5,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - sill')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','J',(Options.nRuns),Options.skipSimulatedAnnealing);   
            end             
            if ismember(6,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - dyke')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','K',(Options.nRuns),Options.skipSimulatedAnnealing);  
            end              
            if ismember(7,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - prolate spheroid')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','L',(Options.nRuns),Options.skipSimulatedAnnealing);  
            end              
            if ismember(8,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - oblate spheroid')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n','O',(Options.nRuns),Options.skipSimulatedAnnealing);                
            end
        end
        
        if Options.OtherSource ==1
            cd(startDir)
            disp('Running GBIS for other source type')
            OutputFilepaths{end+1} = GBISrun(InpFilePath,[1,2],'n',Options.OtherSourceType,(Options.nRuns),Options.skipSimulatedAnnealing);
            close all
            toc
        end 
    else
        tic
        if Options.SourceType==1
            if Options.SeedingRun ==1
                InpFilePathSeed = strcat(InpFilePath(1:end-4),'_Seed.inp');
                disp('Seeding run for Mogi source')
                SeedFilepath = GBISrun(InpFilePathSeed,[1],'n','M',(Options.SeedingnRuns),Options.skipSimulatedAnnealing);
                cd(startDir)
                InpFilePath = ProcessSeedingRun(InpFilePath,SeedFilepath,Options);
            end
            OutputFilepaths{1} = GBISrun(InpFilePath,1,'n','M',(Options.nRuns),Options.skipSimulatedAnnealing);
        elseif Options.SourceType==2
            OutputFilepaths{1} = GBISrun(InpFilePath,1,'n','P',(Options.nRuns),Options.skipSimulatedAnnealing); %Penny runs a lot slower than MOGI (about 30x-40x)
        end
        close all
        toc
        if Options.OtherSource ==1
            tic
            cd(startDir)
            %OutputFilepaths{1} = {OutputFilepaths};
            disp('Running GBIS for other source type')
            OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n',Options.OtherSourceType,(Options.nRuns),Options.skipSimulatedAnnealing);
            close all
            toc
        end

        if Options.SillComparison ==1
            cd(startDir)
            %OutputFilepaths{1} = {OutputFilepaths};
            disp('Running GBIS for Okada sill source')
            OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','S',(Options.nRuns),Options.skipSimulatedAnnealing);
        end

        if Options.DykeComparison ==1
            cd(startDir)
            disp('Running GBIS for Okada dyke')
            OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','D',(Options.nRuns),Options.skipSimulatedAnnealing);
        end

        if Options.CDMComparison ==1
            if ismember(1,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','A',(Options.nRuns),Options.skipSimulatedAnnealing);
            end
            if ismember(2,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - simple sphere')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','B',(Options.nRuns),Options.skipSimulatedAnnealing);
            end
            if ismember(3,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - sphere')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','G',(Options.nRuns),Options.skipSimulatedAnnealing); 
            end               
            if ismember(4,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - symmetric sill')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','I',(Options.nRuns),Options.skipSimulatedAnnealing);     
            end           
            if ismember(5,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - sill')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','J',(Options.nRuns),Options.skipSimulatedAnnealing);    
            end            
            if ismember(6,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - dyke')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','K',(Options.nRuns),Options.skipSimulatedAnnealing);  
            end              
            if ismember(7,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - prolate spheroid')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','L',(Options.nRuns),Options.skipSimulatedAnnealing); 
            end               
            if ismember(8,Options.CDMGeometry)
                cd(startDir)
                disp('Running GBIS for CDM - oblate spheroid')
                OutputFilepaths{end+1} = GBISrun(InpFilePath,[1],'n','O',(Options.nRuns),Options.skipSimulatedAnnealing);                
            end
        end
    end
    cd(startDir)

    if iscell(OutputFilepaths)
        if length(OutputFilepaths) > 1
            for k = 1:length(OutputFilepaths)
                OutputFilepaths{k} = strcat(pwd,OutputFilepaths{k});
            end
        else
            OutputFilepaths{1} = strcat(pwd,OutputFilepaths{1});
        end
    else
        OutputFilepaths = strcat(pwd,OutputFilepaths);
        OutputFilepaths = {OutputFilepaths};
    end
end