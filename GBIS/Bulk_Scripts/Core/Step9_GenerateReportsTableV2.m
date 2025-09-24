function FullTable = Step9_GenerateReportsTableV2(FullTable,OutputFilepath,NumFrames,VolcNames,VolcName,Options)

    for k = 1:length(OutputFilepath)
        disp(['Generating Report ',num2str(k),' out of ',num2str(length(OutputFilepath)),' (~2 mins per report)'])
        SignalLocationGBIS{k} = SignalLocationFromResults(OutputFilepath{k}, VolcName);
        Area = ExtractGBISSignalArea(OutputFilepath{k},Options.AreaCutoff);
        [AspectRatio{k}, Opts{k}] = ExtractSignalShape(OutputFilepath{k},Options);
        SignalLocationGBIS{k}.AreaKm2 = Area;
        ReportFilePath = generateFinalReportPDF(OutputFilepath{k},SignalLocationGBIS{k},Options.Burnin,Opts{k});
        Report = CreatePDF_Report(ReportFilePath,OutputFilepath{k},VolcNames,Opts{k});

        if length(OutputFilepath)>1 && k>1
            disp('Comparing model fits using BIC')
            [DeltaAIC(k), DeltaAICUnw(k), BestModel{k}] = CompareAIC_GBIS(OutputFilepath{1},OutputFilepath{k}); % Assumes first OutputFilePath is Mogi source. For other AIC measurements do manually?
            [DeltaBIC(k), DeltaBICUnw(k), BestModel{k}] = CompareBIC_GBIS(OutputFilepath{1},OutputFilepath{k});
        elseif length(OutputFilepath)==1 || k==1
            DeltaAIC(k) = NaN;
            DeltaAICUnw(k) = NaN;
            DeltaBIC(k) = NaN;
            DeltaBICUnw(k) = NaN;
            BestModel{k} = 'NA';
        end
    end

    if Options.CreateTable ==1
        % Create table of parameters for each run
        if length(OutputFilepath)>1
            for k = 1:length(OutputFilepath)
                disp('Creating output tables')
                AllTables{k} = CreateDeformationCatalogue(OutputFilepath{k},VolcNames,NumFrames,SignalLocationGBIS{k},Opts{k},DeltaAIC(k),DeltaAICUnw(k),DeltaBIC(k),DeltaBICUnw(k),BestModel{k},AspectRatio{k});
                
                if k>1
                    if k==2
                        disp('Merging output tables')
                        Table = outerjoin(AllTables{k-1}, AllTables{k}, 'MergeKeys', true, 'Type', 'full', 'LeftVariables', AllTables{k-1}.Properties.VariableNames, 'RightVariables', AllTables{k}.Properties.VariableNames);
                    end
                    if k>2
                        Table2 = outerjoin(Table, AllTables{k}, 'MergeKeys', true, 'Type', 'full', 'LeftVariables', Table.Properties.VariableNames, 'RightVariables', AllTables{k}.Properties.VariableNames);
                        Table=Table2;
                    end
                end
            end  
        else
            Table = CreateDeformationCatalogue(OutputFilepath{1},VolcNames,NumFrames,SignalLocationGBIS{1},Opts{k},DeltaAIC(1),DeltaAICUnw(1),DeltaBIC(1),DeltaBICUnw(1),BestModel{1},AspectRatio{1});
        end

        disp('Merging new table with previous table')

        if istable(FullTable)
            if width(Table) ~= width(FullTable) || ~all(ismember(Table.Properties.VariableNames, FullTable.Properties.VariableNames))
                %FullTable = outerjoin(FullTable,Table,'MergeKeys',true);
                % Perform an outer join to align the tables and add missing columns
                FullTable = outerjoin(FullTable, Table, 'MergeKeys', true, 'Type', 'full', 'LeftVariables', FullTable.Properties.VariableNames, 'RightVariables', Table.Properties.VariableNames);
                
                % Ensure that the columns of FullTable follow the column order of Table
                FullTable = [FullTable(:, FullTable.Properties.VariableNames(1:width(FullTable) - width(Table))), ...
                FullTable(:, Table.Properties.VariableNames)];
            else
                FullTable = vertcat([FullTable; Table]);
            end
        else
            FullTable = vertcat([FullTable; Table]);
        end
    end
end