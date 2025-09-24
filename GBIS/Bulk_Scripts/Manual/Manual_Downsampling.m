function [loadedData, Filename, Filename_Raw, nObs_SS, nObs_Raw, BoundingBox, NewSS_Factor, NewSS_FactorF] = Manual_Downsampling(Phase,lon,lat,AOI,head,incidence,VolcName,Frame,SignalLocation,Options)
    rad2m = Options.WavelengthM./(4.*pi);
    m2rad= (4.*pi)./Options.WavelengthM;

    n = size(Phase, 1); % Number of rows
    m = size(Phase, 2); % Number of columns

    Extra = '';
    if Options.MaskVolcs ==1
        Extra = append(Extra,'_MaskVolc');
    end
    
    if Options.ICA ==1
        Extra = append(Extra,'_ICA');
    end

    %% Work out coordinates for bounding box and fine bounding box
    % Extract bounds of the full extent
    LatMax = max(lat(:));
    LatMin = min(lat(:));
    LonMax = max(lon(:));
    LonMin = min(lon(:));

    BoundingBox = [LonMin,LatMax,LonMax,LatMin];

    % Make polyshape from big bounding box (covering the full extent of the
    % image)
    BoundingBoxPoly = polyshape([BoundingBox(1) BoundingBox(1) BoundingBox(3)...
        BoundingBox(3)],[BoundingBox(2) BoundingBox(4) BoundingBox(4)...
        BoundingBox(2)]);

    FullResPhase = Phase;
    FullResLat = lat;
    FullResLon = lon;

    SS = ['n','y'];
    VolcanoName = regexp(VolcName,'\S*(?=_[0-9AD]{4}_)','match');
    nObs_Raw = numel(Phase);
    NaN_Threshold = Options.NaN_Thresh_DS;
    FineBoundingBox = AOI.pgon;
    for k = 1:length(SS)
        if k ==1 % Stops phase values being overwritten by a vector
            Phase2 = Phase;
        elseif k==2
            Phase = Phase2;
        end

        if SS(k) == 'y'
            nObs_SS = 0;
            nObs_SS_Fine = 0;
            nObs_SS_Coarse = 0;
            b = 0;
            NewSS_Factor = Options.SS_Factor;
            NewSS_FactorF = Options.SS_FactorF;

            while nObs_SS>Options.Max_nPix || nObs_SS<Options.Min_nPix || (nObs_SS_Coarse/nObs_SS_Fine)<Options.MinPropFF || (nObs_SS_Coarse/nObs_SS_Fine)>Options.MaxPropFF  
            %while nObs_SS>Options.Max_nPix || nObs_SS<Options.Min_nPix || nObs_SS_Coarse<100 || nObs_SS_Coarse>500 %|| ((nObs_SS_Coarse/nObs_SS_Fine)>0.3) %((nObs_SS_Coarse/nObs_SS_Fine<0.1) & nObs_SS_Coarse<100)
                b = b + 1;
                disp(['Downsampling attempt ',num2str(b)])
                if b>1
                    if NewSS_FactorF > 1 && NewSS_FactorF <Options.Max_SS_FactorF 
                        if nObs_SS>Options.Max_nPix
                            NewSS_FactorF = NewSS_FactorF + 1;
                        elseif nObs_SS<Options.Min_nPix
                            NewSS_FactorF = NewSS_FactorF - 1;
                        end
                    end
                    
                    if NewSS_Factor > (Options.Max_SS_FactorF) && NewSS_Factor <Options.Max_SS_Factor
                        if NewSS_Factor > NewSS_FactorF
                            if (nObs_SS_Coarse/nObs_SS_Fine)<Options.MinPropFF %nObs_SS_Coarse<100
                                NewSS_Factor = NewSS_Factor - 1;
                            elseif (nObs_SS_Coarse/nObs_SS_Fine)>Options.MaxPropFF %nObs_SS_Coarse>500
                                NewSS_Factor = NewSS_Factor + 1;
                            elseif NewSS_FactorF==1 && nObs_SS>Options.Max_nPix
                                NewSS_Factor = NewSS_Factor + 1;
                            end
                        else
                            NewSS_Factor = NewSS_Factor + 2;
                        end
                    elseif NewSS_Factor <= (Options.Max_SS_FactorF) && (nObs_SS_Coarse/nObs_SS_Fine)<Options.MinPropFF && NewSS_Factor>NewSS_FactorF
                        % Edge case where there isn't enough far-field points at Options.Max_SS_FactorF so NewSS_Factor needs lowering further
                        NewSS_Factor = NewSS_Factor - 1;
                    end
                end
                % Unique identifier based on parameters
                SS_Style = ['BB_CF_Avg_Pgon_',num2str(NewSS_Factor),'_',num2str(NewSS_FactorF),'_',num2str(NaN_Threshold)];

                if b>1
                    if b==Options.SS_RunLimit || nObs_SS_Coarse==0
                        disp('Taking current number of pixels')
                        break
                    end
                end
            
                % Process lat and lon matricies
                lon2 = lon(1,:);
                lat2 = lat(:,1);
                
                % Give FineSamplingMask
                fine_samp = AOI.Mask';

                % Initialize empty matrices for downsampled image and downsampling locations
                downsampledImg = NaN(n,m);
                downsampledImgFine = NaN(n,m);
                
                downsampledLocs = NaN(n,m);
                downsampledLocsFine = NaN(n,m);
                
                Phase = FullResPhase'; % So the logical indexing assigns the correct phase values to each lat/lon coordinate
                % Iterate through each pixel and downsample
                for i = 1:n
                    for j = 1:m
                        if mod(i,NewSS_Factor) ==0 && mod(j,NewSS_Factor) ==0
                            %Get values and indexes of area
                            LonAvg = mean(lon2(i-(NewSS_Factor-1):i));
                            LatAvg = mean(lat2(j-(NewSS_Factor-1):j));
                
                            LonIdx = round(mean([i-(NewSS_Factor-1),i]));
                            LatIdx = round(mean([j-(NewSS_Factor-1),j]));
                
                            downsampledLocs(LonIdx,LatIdx) = 1;
                
                            %Get Phase values
                            area = Phase(i-(NewSS_Factor-1):i,j-(NewSS_Factor-1):j);
                
                            if nnz(area)/numel(area) > NaN_Threshold
                                downsampledImg(LonIdx,LatIdx) = mean(nonzeros(area(:)));
                            else
                                downsampledImg(LonIdx,LatIdx) = NaN;
                            end
                        end
                
                        if mod(i,NewSS_FactorF) ==0 && mod(j,NewSS_FactorF) ==0
                            %Get values and indexes of area
                            LonAvg = mean(lon2(i-(NewSS_FactorF-1):i));
                            LatAvg = mean(lat2(j-(NewSS_FactorF-1):j));
                
                            LonIdx = round(mean([i-(NewSS_FactorF-1),i]));
                            LatIdx = round(mean([j-(NewSS_FactorF-1),j]));
                
                            downsampledLocsFine(LonIdx,LatIdx) = 1;
                
                            %Get Phase values
                            area = Phase(i-(NewSS_FactorF-1):i,j-(NewSS_FactorF-1):j);
                
                            if nnz(area)/numel(area) > NaN_Threshold
                                downsampledImgFine(LonIdx,LatIdx) = mean(nonzeros(area(:)));
                            else
                                downsampledImgFine(LonIdx,LatIdx) = NaN;
                            end
                        end
                    end
                end
                
                downsampledLocsFine(fine_samp~=1)=NaN;
                downsampledLocs(fine_samp==1)=NaN;
                downsampledLocsCoarse = downsampledLocs;
                
                downsampledImgFine(fine_samp~=1)=NaN;
                downsampledImg(fine_samp==1)=NaN;
                
                downsampledLocs(downsampledLocsFine==1)=1;
                downsampledImg(fine_samp==1)=downsampledImgFine(fine_samp==1);
                
                Check_NaN = isnan(downsampledImg);
                downsampledLocs(Check_NaN)= NaN;
                downsampledLocsFine(Check_NaN)= NaN;
                downsampledLocsCoarse(Check_NaN)= NaN;

                nObs_SS_Fine = sum(downsampledLocsFine(:),'omitnan');
                nObs_SS_Coarse = sum(downsampledLocsCoarse(:),'omitnan');
                nObs_SS = sum(downsampledLocs(:),'omitnan');

                DS_Stats.FactorF(b) = NewSS_FactorF;
                DS_Stats.Factor(b) = NewSS_Factor;
                DS_Stats.SS_Fine(b) = nObs_SS_Fine;
                DS_Stats.SS_Coarse(b) = nObs_SS_Coarse;
                DS_Stats.SS(b) = nObs_SS;
                DS_Stats.SS_Ratio(b) = round((nObs_SS_Coarse./nObs_SS_Fine).*100);
                
                % Find downsampled locations
                [xDownsampled, yDownsampled] = find(~isnan(downsampledLocs));
                Null2 = ~isnan(downsampledImg(:));
                Null = ~isnan(downsampledImg);
                downsampledImg = downsampledImg(Null);

                % Find indicies for fine and coarse downsampled pixels
                isCoarseVec = ~isnan(downsampledLocsCoarse(:));
                coarse_indices_logical = isCoarseVec(Null2);
                CoarseIdxs = find(coarse_indices_logical);

                isFineVec = ~isnan(downsampledLocsFine(:));
                fine_indices_logical = isFineVec(Null2);
                FineIdxs = find(fine_indices_logical);
                
                %Convert downsampled x and y locations into Lat or Lon
                Lon3 = zeros(length(xDownsampled),1);
                Lat3 = zeros(length(yDownsampled),1);
                
                for x = 1:length(yDownsampled)
                    Lon3(x) = lon2(xDownsampled(x));
                    Lat3(x) = lat2(yDownsampled(x));
                end
                
                loadedData.Lon = Lon3;
                loadedData.Lat = Lat3;
                loadedData.Phase = downsampledImg;
            
                if Options.MaskVolcs ==1
                    SS_Style = append(SS_Style,'_MaskVolc');
                end
            
                if Options.ICA ==1
                    SS_Style = append(SS_Style,'_ICA');
                end

                if Options.Adjust_SS_Factor == 0
                    break
                end
            end
        
        %% No subsampling
        elseif SS(k) == 'n'
            % Initialise empty output variables
            nObs_SS = [];
            CoarseIdxs = [];
            FineIdxs = [];
        
            loadedData.Lon = reshape(lon,[],1);
            loadedData.Lat = reshape(lat,[],1);
            Phase = reshape(Phase,[],1);
            loadedData.Phase = Phase;
        
            SS_Style = 'No_SS';

            NewSS_Factor = Options.SS_Factor;
            NewSS_FactorF = Options.SS_FactorF;
            
            if Options.MaskVolcs ==1
                SS_Style = append(SS_Style,'_MaskVolc');
            end
        
            if Options.ICA ==1
                SS_Style = append(SS_Style,'_ICA');
            end
        else
            error('Error. Please specify if the data should be subsampled using "y" (yes) or "n" (no)')
        end
        
        
        %% Remove Null values
        %Find and remove zero or NaN values
        Null = (loadedData.Phase~=0) & ~isnan(loadedData.Phase);
        loadedData.FullPhase = loadedData.Phase;
        loadedData.FullLat = loadedData.Lat;
        loadedData.FullLon = loadedData.Lon;
        loadedData.Phase = loadedData.Phase(Null);
        loadedData.Lat = loadedData.Lat(Null);
        loadedData.Lon = loadedData.Lon(Null);
        
        %% Prepare final parts of input data
        %Create vectors of the heading and incidence angle
        loadedData.Heading = (zeros(size(loadedData.Phase)))+head;
        loadedData.Inc = (zeros(size(loadedData.Phase)))+incidence;

        %% Manually apply offset
        if k==1 && Options.PreProcOffset ==1
            % Apply manual offset
            [loadedData.Phase,loadedData.Offset] = RemovePhaseOffset(FineBoundingBox,loadedData);
        end

        if k==2 && Options.PreProcOffset ==1
            loadedData.Offset = loadedData.Offset;
            loadedData.Phase = loadedData.Phase - loadedData.Offset;
        end

        if Options.PreProcOffset ==0
            loadedData.Offset = [];
        end
        
        %% Write and save input file
        Lon = loadedData.Lon;
        Lat = loadedData.Lat;
        Phase = loadedData.Phase;
        Inc = loadedData.Inc;
        Heading = loadedData.Heading;
        Offset = loadedData.Offset;
        FullPhase = loadedData.FullPhase;
        FullLat = loadedData.FullLat;
        FullLon = loadedData.FullLon;
        
        if k==1
            Filename_Raw = char(strcat(pwd,'/InputData/',VolcanoName{1},'_',Frame,'_',SS_Style,'_',Options.RunID,'_.mat'))
            save(Filename_Raw,'Lon','Lat','Phase','Inc','Heading','Offset','FineBoundingBox','CoarseIdxs','FineIdxs','FullResPhase',"FullResLat","FullResLon");
        elseif k==2
            Filename = char(strcat(pwd,'/InputData/',VolcanoName{1},'_',Frame,'_',SS_Style,'_',Options.RunID,'_.mat'))
            save(Filename,'Lon','Lat','Phase','Inc','Heading','Offset','FineBoundingBox','CoarseIdxs','FineIdxs','nObs_SS','nObs_Raw','nObs_SS_Fine','nObs_SS_Coarse','DS_Stats');
        end
        
        
        %% Save outputs from Otsu thresholding
        if SS(k) == 'y'
            disp('Creating and saving downsampling figures')
            % Create Downsampling figure
            DS_Fig = figure()
            T = tiledlayout(1,2,"TileSpacing","none","Padding","compact");
            ax1 = nexttile;
            h = imagesc(-1*rad2m.*FullResPhase);
            axis square
            box(ax1,'on')
            colormap(ax1,jet)
            c = 0.1;
            caxis([-c c])
            set(h, 'AlphaData',FullResPhase~=0)
            hold on
        
            plot(AOI.pgon,"LineStyle","--",FaceAlpha=0,LineWidth=2)
            xticklabels({''})
            yticklabels({''})
            set(gca,'XTick',[])
            set(gca,'YTick',[])
            hold off
            
            ax2 = nexttile;
            scatter(loadedData.Lon,loadedData.Lat,10,-1*rad2m.*loadedData.Phase,'filled','square');
            axis square
            xlim([min(FullResLon(:)),max(FullResLon(:))]);
            ylim([min(FullResLat(:)),max(FullResLat(:))]);
            box(ax2,'on')
            colormap(ax2,jet)
            caxis([-c c])
            c = colorbar(gca,"eastoutside");
            c.Label.String = 'LOS Displacement (m)';
            xticklabels({''})
            yticklabels({''})
            set(gca,'XTick',[])
            set(gca,'YTick',[])
            hold off
            
            FigFilename = strcat(pwd,'/Bounding_Boxes/',VolcName,'_ManualDSFig_',Extra,'.png');
            saveas(DS_Fig,FigFilename);

            save([pwd,'/Spatial_Parameters/',VolcName,'_Shape_',num2str(Options.Otsu_BB_Shape),Extra,'_InitialSignalLocation.mat'],'SignalLocation');
            save([pwd,'/nObs/',VolcName,'_',SS_Style,'_nOBS.mat'],'nObs_SS','nObs_Raw');
        end
    end
end