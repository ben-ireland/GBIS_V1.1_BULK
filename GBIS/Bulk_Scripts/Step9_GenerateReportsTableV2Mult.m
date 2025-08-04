function FullTable = Step9_GenerateReportsTableV2Mult(FullTable,OutputFilepath,NumFrames,VolcNames,VolcName,Options)

    for k = 1:length(OutputFilepath)
        disp(['Generating Report ',num2str(k),' out of ',num2str(length(OutputFilepath)),' (~2 mins per report)'])
        SignalLocationGBIS{k} = SignalLocationFromResultsMult2(OutputFilepath{k}, VolcName);
        [Area{k},AreaTot{k}] = ExtractGBISSignalAreaMult(OutputFilepath{k},Options.AreaCutoff);
        [AspectRatio{k}, Options] = ExtractSignalShape(OutputFilepath{k},Options);
        SignalLocationGBIS{k}.AreaKm2 = AreaTot{k};
        ReportFilePath = generateFinalReportPDF_Mult(OutputFilepath{k},Options.Burnin,Options);
        Report = CreatePDF_ReportMult(ReportFilePath,OutputFilepath{k},VolcNames,Options);

        if length(OutputFilepath)>1 && k>1
            disp('Comparing model fits using AIC')
            [DeltaAIC(k), BestModel{k}] = CompareAIC_GBIS(OutputFilepath{1},OutputFilepath{k}); % Assumes first OutputFilePath is Mogi source. For other AIC measurements do manually?
        elseif length(OutputFilepath)==1 || k==1
            DeltaAIC(k) = NaN;
            BestModel{k} = 'NA';
        end
    end

    if Options.CreateTable ==1
        % Create table of parameters for each run
        if length(OutputFilepath)>1
            for k = 1:length(OutputFilepath)
                disp('Creating output tables')
                AllTables{k} = CreateDeformationCatalogueMult2(OutputFilepath{k},VolcNames,NumFrames,SignalLocationGBIS{k},Options,DeltaAIC(k),BestModel{k},AspectRatio{k});
                %TablePen = CreateDeformationCatalogue(OutputFilepath{2},VolcNames,NumFrames,SignalLocationGBISPen,Options.Burnin,DeltaAIC,BestModel);
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
            Table = CreateDeformationCatalogueMult2(OutputFilepath{1},VolcNames,NumFrames,SignalLocationGBIS{1},Options,DeltaAIC(1),BestModel{1},AspectRatio{1});
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