function InpFilePath = Step7_PrepInputFile(inputFileName,outputFileName,FineBoundingBox,BoundingBox,nObs_Raw,Filename,Filename_Raw,j,Options)
    if ~exist([pwd,'/InputFiles'],'dir')
        mkdir(pwd,'InputFiles')
        addpath([pwd,'/InputFiles'])
    end
    % Initialise variables and arrays
    Sill = [];
    Range = [];
    Nugget = [];

    %inputFileName = char(strcat(inputFiles.folder,'/',inputFiles.name));
    
    % Read in Generic input file
    if j==1
        inputFileID = fopen(inputFileName, 'r');
    else
        inputFileID = fopen(outputFileName, 'r');
    end
    textLine = fgetl(inputFileID); 
    
    while ischar(textLine)
        eval(textLine)
        textLine = fgetl(inputFileID);
    end
    
    fclose(inputFileID);

    %% Change downsampling parameters
    if j ==1
        InpFilePath = modifyInpFile2(inputFileName, outputFileName, 'geo.SS_Factor', num2str(geo.SS_Factor), num2str(Options.SS_Factor), 'n',[]);
        inputFileName = InpFilePath;
    elseif j==2
        InpFilePath = modifyInpFile2(inputFileName, outputFileName, 'geo.SS_Factor', num2str(geo.SS_Factor), num2str(Options.SS_Factor), 'y',[]);
    end
    
    InpFilePath = modifyInpFile2(inputFileName, outputFileName, 'geo.SS_Factor', num2str(geo.SS_Factor), num2str(Options.SS_Factor), 'y',[]);

    
    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'geo.SS_FactorF', num2str(geo.SS_FactorF), num2str(Options.SS_FactorF), 'y',[]);
    
    %Change bounding box of the full image and reference point
    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'geo.boundingBox', ['[',sprintf('%.4f',geo.boundingBox(1)),';',sprintf('%.4f',geo.boundingBox(2)),';',sprintf('%.4f',geo.boundingBox(3)),';',sprintf('%.4f',geo.boundingBox(4)),';]'], ['[',num2str(BoundingBox(1)),';',num2str(BoundingBox(2)),';',num2str(BoundingBox(3)),';',num2str(BoundingBox(4)),';]'], 'y',1);
    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'geo.referencePoint', ['[',sprintf('%.4f',geo.referencePoint(1)),';',sprintf('%.4f',geo.referencePoint(2)),']'], ['[',num2str(BoundingBox(1)),';',num2str(BoundingBox(4)),']'], 'y',1);

    
    %Extract max coordinates (m) to be used in GBIS based off the size
    %of the image and spatial resolution (assumes a square frame)
    MaxCoords = sqrt(nObs_Raw)*Options.SpatialRes;

    %% Change model bounds
    if Options.Bounds ==1
        if Options.SourceType==1 || Options.PennyComparison ==1
            if Options.BoundLimits ==1
                % Mogi Constrain locational bounds to within the extent of the FineBoundingBox
                [Xlims, Ylims] = boundingbox(FineBoundingBox);
                startBounds = [round((mean(Xlims)*Options.SpatialRes));round((mean(Ylims)*Options.SpatialRes));Options.MogiStartDepth;Options.MogiStartVol]; % 4 km based on median depth from Ebmeier et al. (2018); 7e06 m^3 volume based on rounded injection volume (Delaney, 1994) from median depth (4 km) and displacements (~10 cm) of intrusions (Biggs and Pritchard, 2017)
                lowerBounds = [round((Xlims(1)*Options.SpatialRes));round((Ylims(1)*Options.SpatialRes));Options.MogiMinDepth;Options.MogiMinVol]; % Lower depth and volume based on rounded 1st percentile of depth Ebmeier et al. (2018) (0.5 km) and volume of a 4 km point source producing the 90th percentile displacement (~95 cm; 10^8 m3) of Biggs and Pritchard, 2017.
                upperBounds = [round((Xlims(2)*Options.SpatialRes));round((Ylims(2)*Options.SpatialRes));Options.MogiMaxDepth;Options.MogiMaxVol]; % Upper depth and volume based on rounded 90th percentile of depth Ebmeier et al. (2018) (10 km) and volume of a 4 km point source producing the 90th percentile displacement (~95 cm; 10^8 m3) of Biggs and Pritchard, 2017.
            elseif Options.BoundLimits ==2
                %Mogi - % Change the bounds based on the size of the
                %image - start in the middle
                startBounds = [(MaxCoords/2);(MaxCoords/2);Options.MogiStartDepth;Options.MogiStartVol]; %
                lowerBounds = [(MaxCoords*0.05);(MaxCoords*0.05);Options.MogiMinDepth;Options.MogiMinVol]; 
                upperBounds = [(MaxCoords*0.95);(MaxCoords*0.95);Options.MogiMaxDepth;Options.MogiMaxVol]; 
            end

            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.mogi.start', ['[',num2str(modelInput.mogi.start(1)),';',num2str(modelInput.mogi.start(2)),';',num2str(modelInput.mogi.start(3)),';',num2str(modelInput.mogi.start(4)),';]'], ['[',num2str(startBounds(1)),';',num2str(startBounds(2)),';',num2str(startBounds(3)),';',num2str(startBounds(4)),';]'], 'y',1);
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.mogi.lower', ['[',num2str(modelInput.mogi.lower(1)),';',num2str(modelInput.mogi.lower(2)),';',num2str(modelInput.mogi.lower(3)),';',num2str(modelInput.mogi.lower(4)),';]'], ['[',num2str(lowerBounds(1)),';',num2str(lowerBounds(2)),';',num2str(lowerBounds(3)),';',num2str(lowerBounds(4)),';]'], 'y',1);
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.mogi.upper', ['[',num2str(modelInput.mogi.upper(1)),';',num2str(modelInput.mogi.upper(2)),';',num2str(modelInput.mogi.upper(3)),';',num2str(modelInput.mogi.upper(4)),';]'], ['[',num2str(upperBounds(1)),';',num2str(upperBounds(2)),';',num2str(upperBounds(3)),';',num2str(upperBounds(4)),';]'], 'y',1);
        end

        if Options.SourceType==2 || Options.PennyComparison ==1 || ((matches(Options.OtherSourceType,'P') || matches(Options.OtherSourceType,'C') || matches(Options.OtherSourceType,'V')) && Options.OtherSource ==1)
            %Penny crack - x,y,z,r,dp/mu
            if Options.BoundLimits ==1
                % Penny - Constrain locational bounds to within the extent of the FineBoundingBox
                % x/y location based on FineBoundingBox, z location based on previous catalogues (see Mogi description)
                % Radius based on East African Rift System (Biggs et al. 2009; 2011)
                [Xlims, Ylims] = boundingbox(FineBoundingBox);
                startBoundsPen = [round((mean(Xlims)*Options.SpatialRes));round((mean(Ylims)*Options.SpatialRes));Options.PennyStartDepth;Options.PennyStartRadius;Options.PennyStartDPMu]; %
                lowerBoundsPen = [round((Xlims(1)*Options.SpatialRes));round((Ylims(1)*Options.SpatialRes));Options.PennyMinDepth;Options.PennyMinRadius;Options.PennyMinDPMu]; 
                upperBoundsPen = [round((Xlims(2)*Options.SpatialRes));round((Ylims(2)*Options.SpatialRes));Options.PennyMaxDepth;Options.PennyMaxRadius;Options.PennyMaxDPMu]; 
            elseif Options.BoundLimits ==2
                startBoundsPen = [(MaxCoords/2);(MaxCoords/2);Options.PennyStartDepth;Options.PennyStartRadius;Options.PennyStartDPMu]; %
                lowerBoundsPen = [(MaxCoords*0.05);(MaxCoords*0.05);Options.PennyMinDepth;Options.PennyMinRadius;Options.PennyMinDPMu]; 
                upperBoundsPen = [(MaxCoords*0.95);(MaxCoords*0.95);Options.PennyMaxDepth;Options.PennyMaxRadius;Options.PennyMaxDPMu]; 
            end

            if Options.PennyType ==1
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.penny.start', ['[',num2str(modelInput.penny.start(1)),';',num2str(modelInput.penny.start(2)),';',num2str(modelInput.penny.start(3)),';',num2str(modelInput.penny.start(4)),';',num2str(modelInput.penny.start(5)),';]'], ['[',num2str(startBoundsPen(1)),';',num2str(startBoundsPen(2)),';',num2str(startBoundsPen(3)),';',num2str(startBoundsPen(4)),';',num2str(startBoundsPen(5)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.penny.lower', ['[',num2str(modelInput.penny.lower(1)),';',num2str(modelInput.penny.lower(2)),';',num2str(modelInput.penny.lower(3)),';',num2str(modelInput.penny.lower(4)),';',num2str(modelInput.penny.lower(5)),';]'], ['[',num2str(lowerBoundsPen(1)),';',num2str(lowerBoundsPen(2)),';',num2str(lowerBoundsPen(3)),';',num2str(lowerBoundsPen(4)),';',num2str(lowerBoundsPen(5)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.penny.upper', ['[',num2str(modelInput.penny.upper(1)),';',num2str(modelInput.penny.upper(2)),';',num2str(modelInput.penny.upper(3)),';',num2str(modelInput.penny.upper(4)),';',num2str(modelInput.penny.upper(5)),';]'], ['[',num2str(upperBoundsPen(1)),';',num2str(upperBoundsPen(2)),';',num2str(upperBoundsPen(3)),';',num2str(upperBoundsPen(4)),';',num2str(upperBoundsPen(5)),';]'], 'y',1);
            elseif Options.PennyType ==2
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.SunCrack.start', ['[',num2str(modelInput.SunCrack.start(1)),';',num2str(modelInput.SunCrack.start(2)),';',num2str(modelInput.SunCrack.start(3)),';',num2str(modelInput.SunCrack.start(4)),';',num2str(modelInput.SunCrack.start(5)),';]'], ['[',num2str(startBoundsPen(1)),';',num2str(startBoundsPen(2)),';',num2str(startBoundsPen(3)),';',num2str(startBoundsPen(4)),';',num2str(startBoundsPen(5)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.SunCrack.lower', ['[',num2str(modelInput.SunCrack.lower(1)),';',num2str(modelInput.SunCrack.lower(2)),';',num2str(modelInput.SunCrack.lower(3)),';',num2str(modelInput.SunCrack.lower(4)),';',num2str(modelInput.SunCrack.lower(5)),';]'], ['[',num2str(lowerBoundsPen(1)),';',num2str(lowerBoundsPen(2)),';',num2str(lowerBoundsPen(3)),';',num2str(lowerBoundsPen(4)),';',num2str(lowerBoundsPen(5)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.SunCrack.upper', ['[',num2str(modelInput.SunCrack.upper(1)),';',num2str(modelInput.SunCrack.upper(2)),';',num2str(modelInput.SunCrack.upper(3)),';',num2str(modelInput.SunCrack.upper(4)),';',num2str(modelInput.SunCrack.upper(5)),';]'], ['[',num2str(upperBoundsPen(1)),';',num2str(upperBoundsPen(2)),';',num2str(upperBoundsPen(3)),';',num2str(upperBoundsPen(4)),';',num2str(upperBoundsPen(5)),';]'], 'y',1);
            elseif Options.PennyType ==3
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.SunVCrack.start', ['[',num2str(modelInput.SunVCrack.start(1)),';',num2str(modelInput.SunVCrack.start(2)),';',num2str(modelInput.SunVCrack.start(3)),';',num2str(modelInput.SunVCrack.start(4)),';',num2str(modelInput.SunVCrack.start(5)),';]'], ['[',num2str(startBoundsPen(1)),';',num2str(startBoundsPen(2)),';',num2str(startBoundsPen(3)),';',num2str(startBoundsPen(4)),';',num2str(Options.MogiStartVol),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.SunVCrack.lower', ['[',num2str(modelInput.SunVCrack.lower(1)),';',num2str(modelInput.SunVCrack.lower(2)),';',num2str(modelInput.SunVCrack.lower(3)),';',num2str(modelInput.SunVCrack.lower(4)),';',num2str(modelInput.SunVCrack.lower(5)),';]'], ['[',num2str(lowerBoundsPen(1)),';',num2str(lowerBoundsPen(2)),';',num2str(lowerBoundsPen(3)),';',num2str(lowerBoundsPen(4)),';',num2str(Options.MogiMinVol),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.SunVCrack.upper', ['[',num2str(modelInput.SunVCrack.upper(1)),';',num2str(modelInput.SunVCrack.upper(2)),';',num2str(modelInput.SunVCrack.upper(3)),';',num2str(modelInput.SunVCrack.upper(4)),';',num2str(modelInput.SunVCrack.upper(5)),';]'], ['[',num2str(upperBoundsPen(1)),';',num2str(upperBoundsPen(2)),';',num2str(upperBoundsPen(3)),';',num2str(upperBoundsPen(4)),';',num2str(Options.MogiMaxVol),';]'], 'y',1);
            end
        end

        if Options.SillComparison==1 || (matches(Options.OtherSourceType,'S') && Options.OtherSource ==1)
            if Options.BoundLimits ==1
            [Xlims, Ylims] = boundingbox(FineBoundingBox);
                startBoundsSill = [Options.SillStartLength; Options.SillStartWidth; Options.SillStartDepth; Options.SillStartStrike; round((mean(Xlims)*Options.SpatialRes));round((mean(Ylims)*Options.SpatialRes)); Options.SillStartOpening];
                lowerBoundsSill = [Options.SillMinLength; Options.SillMinWidth; Options.SillMinDepth; Options.SillMinStrike;round((Xlims(1)*Options.SpatialRes));round((Ylims(1)*Options.SpatialRes)); Options.SillMinOpening];
                upperBoundsSill = [Options.SillMaxLength; Options.SillMaxWidth; Options.SillMaxDepth; Options.SillMaxStrike;round((Xlims(2)*Options.SpatialRes));round((Ylims(2)*Options.SpatialRes)); Options.SillMaxOpening];
            
            elseif Options.BoundLimits ==2
                startBoundsSill = [Options.SillStartLength; Options.SillStartWidth; Options.SillStartDepth; Options.SillStartStrike;(MaxCoords/2);(MaxCoords/2);Options.SillStartOpening];
                lowerBoundsSill = [Options.SillMinLength; Options.SillMinWidth; Options.SillMinDepth; Options.SillMinStrike;(MaxCoords*0.05);(MaxCoords*0.05); Options.SillMinOpening];
                upperBoundsSill = [Options.SillMaxLength; Options.SillMaxWidth; Options.SillMaxDepth; Options.SillMaxStrike;(MaxCoords*0.95);(MaxCoords*0.95); Options.SillMaxOpening];
            end
            
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.sill.start', ['[',num2str(modelInput.sill.start(1)),';',num2str(modelInput.sill.start(2)),';',num2str(modelInput.sill.start(3)),';',num2str(modelInput.sill.start(4)),';',num2str(modelInput.sill.start(5)),';',num2str(modelInput.sill.start(6)),';',num2str(modelInput.sill.start(7)),';]'], ['[',num2str(startBoundsSill(1)),';',num2str(startBoundsSill(2)),';',num2str(startBoundsSill(3)),';',num2str(startBoundsSill(4)),';',num2str(startBoundsSill(5)),';',num2str(startBoundsSill(6)),';',num2str(startBoundsSill(7)),';]'], 'y',1);
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.sill.lower', ['[',num2str(modelInput.sill.lower(1)),';',num2str(modelInput.sill.lower(2)),';',num2str(modelInput.sill.lower(3)),';',num2str(modelInput.sill.lower(4)),';',num2str(modelInput.sill.lower(5)),';',num2str(modelInput.sill.lower(6)),';',num2str(modelInput.sill.lower(7)),';]'], ['[',num2str(lowerBoundsSill(1)),';',num2str(lowerBoundsSill(2)),';',num2str(lowerBoundsSill(3)),';',num2str(lowerBoundsSill(4)),';',num2str(lowerBoundsSill(5)),';',num2str(lowerBoundsSill(6)),';',num2str(lowerBoundsSill(7)),';]'], 'y',1);
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.sill.upper', ['[',num2str(modelInput.sill.upper(1)),';',num2str(modelInput.sill.upper(2)),';',num2str(modelInput.sill.upper(3)),';',num2str(modelInput.sill.upper(4)),';',num2str(modelInput.sill.upper(5)),';',num2str(modelInput.sill.upper(6)),';',num2str(modelInput.sill.upper(7)),';]'], ['[',num2str(upperBoundsSill(1)),';',num2str(upperBoundsSill(2)),';',num2str(upperBoundsSill(3)),';',num2str(upperBoundsSill(4)),';',num2str(upperBoundsSill(5)),';',num2str(upperBoundsSill(6)),';',num2str(upperBoundsSill(7)),';]'], 'y',1);
        end

        if Options.YangComparison==1 || ((matches(Options.OtherSourceType,'Y') || matches(Options.OtherSourceType,'E') || matches(Options.OtherSourceType,'R')) && Options.OtherSource ==1)
            if Options.BoundLimits ==1
            [Xlims, Ylims] = boundingbox(FineBoundingBox);
                if Options.YangType ==1
                    startBoundsYang = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.YangStartZ; Options.YangStarta; Options.YangStartab;Options.YangStartTrend; Options.YangStartPlunge; Options.YangStartDpMu];
                    lowerBoundsYang = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.YangMinZ; Options.YangMina; Options.YangMinab;Options.YangMinTrend; Options.YangMinPlunge; Options.YangMinDpMu];
                    upperBoundsYang = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.YangMaxZ; Options.YangMaxa; Options.YangMaxab;Options.YangMaxTrend; Options.YangMaxPlunge; Options.YangMaxDpMu];
                elseif Options.YangType ==2
                    startBoundsYang = [Options.YangStarta; Options.YangStartb; Options.YangStartPlunge; Options.YangStartTrend; round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.YangStartZ; Options.YangStartVolume];
                    lowerBoundsYang = [Options.YangMina; Options.YangMinb; Options.YangMinPlunge; Options.YangMinTrend; round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.YangMinZ; Options.YangMinVolume];
                    upperBoundsYang = [Options.YangMaxa; Options.YangMaxb; Options.YangMaxPlunge; Options.YangMaxTrend; round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.YangMaxZ; Options.YangMaxVolume];
                elseif Options.YangType ==3
                    startBoundsYang = [Options.YangStarta; Options.YangStartb; Options.YangStartPlunge; Options.YangStartTrend; round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.YangStartZ; Options.YangStartDpMu];
                    lowerBoundsYang = [Options.YangMina; Options.YangMinb; Options.YangMinPlunge; Options.YangMinTrend; round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.YangMinZ; Options.YangMinDpMu];
                    upperBoundsYang = [Options.YangMaxa; Options.YangMaxb; Options.YangMaxPlunge; Options.YangMaxTrend; round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.YangMaxZ; Options.YangMaxDpMu];
                end
            
            elseif Options.BoundLimits ==2
                if Options.YangType ==1
                    startBoundsYang = [(MaxCoords/2);(MaxCoords/2); Options.YangStartZ; Options.YangStarta; Options.YangStartab;Options.YangStartTrend; Options.YangStartPlunge; Options.YangStartDpMu];
                    lowerBoundsYang = [(MaxCoords*0.05);(MaxCoords*0.05); Options.YangMinZ; Options.YangMina; Options.YangMinab;Options.YangMinTrend; Options.YangMinPlunge; Options.YangMinDpMu];
                    upperBoundsYang = [(MaxCoords*0.95);(MaxCoords*0.95); Options.YangMaxZ; Options.YangMaxa; Options.YangMaxab;Options.YangMaxTrend; Options.YangMaxPlunge; Options.YangMaxDpMu];
                elseif Options.YangType ==2
                    startBoundsYang = [Options.YangStarta; Options.YangStartb; Options.YangStartPlunge; Options.YangStartTrend; (MaxCoords/2);(MaxCoords/2); Options.YangStartZ; Options.YangStartVolume];
                    lowerBoundsYang = [Options.YangMina; Options.YangMinb; Options.YangMinPlunge; Options.YangMinTrend; (MaxCoords*0.05);(MaxCoords*0.05); Options.YangMinZ; Options.YangMinVolume];
                    upperBoundsYang = [Options.YangMaxa; Options.YangMaxb; Options.YangMaxPlunge; Options.YangMaxTrend; round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.YangMaxZ; Options.YangMaxVolume];
                elseif Options.YangType ==3
                    startBoundsYang = [Options.YangStarta; Options.YangStartb; Options.YangStartPlunge; Options.YangStartTrend; (MaxCoords/2);(MaxCoords/2); Options.YangStartZ; Options.YangStartDpMu];
                    lowerBoundsYang = [Options.YangMina; Options.YangMinb; Options.YangMinPlunge; Options.YangMinTrend; (MaxCoords*0.05);(MaxCoords*0.05); Options.YangMinZ; Options.YangMinDpMu];
                    upperBoundsYang = [Options.YangMaxa; Options.YangMaxb; Options.YangMaxPlunge; Options.YangMaxTrend; (MaxCoords*0.95);(MaxCoords*0.95); Options.YangMaxZ; Options.YangMaxDpMu];
                end
            end
            
            if Options.YangType ==1
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.yang.start', ['[',num2str(modelInput.yang.start(1)),';',num2str(modelInput.yang.start(2)),';',num2str(modelInput.yang.start(3)),';',num2str(modelInput.yang.start(4)),';',num2str(modelInput.yang.start(5)),';',num2str(modelInput.yang.start(6)),';',num2str(modelInput.yang.start(7)),';',num2str(modelInput.yang.start(8)),';]'], ['[',num2str(startBoundsYang(1)),';',num2str(startBoundsYang(2)),';',num2str(startBoundsYang(3)),';',num2str(startBoundsYang(4)),';',num2str(startBoundsYang(5)),';',num2str(startBoundsYang(6)),';',num2str(startBoundsYang(7)),';',num2str(startBoundsYang(8)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.yang.lower', ['[',num2str(modelInput.yang.lower(1)),';',num2str(modelInput.yang.lower(2)),';',num2str(modelInput.yang.lower(3)),';',num2str(modelInput.yang.lower(4)),';',num2str(modelInput.yang.lower(5)),';',num2str(modelInput.yang.lower(6)),';',num2str(modelInput.yang.lower(7)),';',num2str(modelInput.yang.lower(8)),';]'], ['[',num2str(lowerBoundsYang(1)),';',num2str(lowerBoundsYang(2)),';',num2str(lowerBoundsYang(3)),';',num2str(lowerBoundsYang(4)),';',num2str(lowerBoundsYang(5)),';',num2str(lowerBoundsYang(6)),';',num2str(lowerBoundsYang(7)),';',num2str(lowerBoundsYang(8)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.yang.upper', ['[',num2str(modelInput.yang.upper(1)),';',num2str(modelInput.yang.upper(2)),';',num2str(modelInput.yang.upper(3)),';',num2str(modelInput.yang.upper(4)),';',num2str(modelInput.yang.upper(5)),';',num2str(modelInput.yang.upper(6)),';',num2str(modelInput.yang.upper(7)),';',num2str(modelInput.yang.upper(8)),';]'], ['[',num2str(upperBoundsYang(1)),';',num2str(upperBoundsYang(2)),';',num2str(upperBoundsYang(3)),';',num2str(upperBoundsYang(4)),';',num2str(upperBoundsYang(5)),';',num2str(upperBoundsYang(6)),';',num2str(upperBoundsYang(7)),';',num2str(upperBoundsYang(8)),';]'], 'y',1);
            elseif Options.YangType ==2
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cerv.start', ['[',num2str(modelInput.cerv.start(1)),';',num2str(modelInput.cerv.start(2)),';',num2str(modelInput.cerv.start(3)),';',num2str(modelInput.cerv.start(4)),';',num2str(modelInput.cerv.start(5)),';',num2str(modelInput.cerv.start(6)),';',num2str(modelInput.cerv.start(7)),';',num2str(modelInput.cerv.start(8)),';]'], ['[',num2str(startBoundsYang(1)),';',num2str(startBoundsYang(2)),';',num2str(startBoundsYang(3)),';',num2str(startBoundsYang(4)),';',num2str(startBoundsYang(5)),';',num2str(startBoundsYang(6)),';',num2str(startBoundsYang(7)),';',num2str(startBoundsYang(8)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cerv.lower', ['[',num2str(modelInput.cerv.lower(1)),';',num2str(modelInput.cerv.lower(2)),';',num2str(modelInput.cerv.lower(3)),';',num2str(modelInput.cerv.lower(4)),';',num2str(modelInput.cerv.lower(5)),';',num2str(modelInput.cerv.lower(6)),';',num2str(modelInput.cerv.lower(7)),';',num2str(modelInput.cerv.lower(8)),';]'], ['[',num2str(lowerBoundsYang(1)),';',num2str(lowerBoundsYang(2)),';',num2str(lowerBoundsYang(3)),';',num2str(lowerBoundsYang(4)),';',num2str(lowerBoundsYang(5)),';',num2str(lowerBoundsYang(6)),';',num2str(lowerBoundsYang(7)),';',num2str(lowerBoundsYang(8)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cerv.upper', ['[',num2str(modelInput.cerv.upper(1)),';',num2str(modelInput.cerv.upper(2)),';',num2str(modelInput.cerv.upper(3)),';',num2str(modelInput.cerv.upper(4)),';',num2str(modelInput.cerv.upper(5)),';',num2str(modelInput.cerv.upper(6)),';',num2str(modelInput.cerv.upper(7)),';',num2str(modelInput.cerv.upper(8)),';]'], ['[',num2str(upperBoundsYang(1)),';',num2str(upperBoundsYang(2)),';',num2str(upperBoundsYang(3)),';',num2str(upperBoundsYang(4)),';',num2str(upperBoundsYang(5)),';',num2str(upperBoundsYang(6)),';',num2str(upperBoundsYang(7)),';',num2str(upperBoundsYang(8)),';]'], 'y',1);
            elseif Options.YangType ==3
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cerp.start', ['[',num2str(modelInput.cerp.start(1)),';',num2str(modelInput.cerp.start(2)),';',num2str(modelInput.cerp.start(3)),';',num2str(modelInput.cerp.start(4)),';',num2str(modelInput.cerp.start(5)),';',num2str(modelInput.cerp.start(6)),';',num2str(modelInput.cerp.start(7)),';',num2str(modelInput.cerp.start(8)),';]'], ['[',num2str(startBoundsYang(1)),';',num2str(startBoundsYang(2)),';',num2str(startBoundsYang(3)),';',num2str(startBoundsYang(4)),';',num2str(startBoundsYang(5)),';',num2str(startBoundsYang(6)),';',num2str(startBoundsYang(7)),';',num2str(startBoundsYang(8)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cerp.lower', ['[',num2str(modelInput.cerp.lower(1)),';',num2str(modelInput.cerp.lower(2)),';',num2str(modelInput.cerp.lower(3)),';',num2str(modelInput.cerp.lower(4)),';',num2str(modelInput.cerp.lower(5)),';',num2str(modelInput.cerp.lower(6)),';',num2str(modelInput.cerp.lower(7)),';',num2str(modelInput.cerp.lower(8)),';]'], ['[',num2str(lowerBoundsYang(1)),';',num2str(lowerBoundsYang(2)),';',num2str(lowerBoundsYang(3)),';',num2str(lowerBoundsYang(4)),';',num2str(lowerBoundsYang(5)),';',num2str(lowerBoundsYang(6)),';',num2str(lowerBoundsYang(7)),';',num2str(lowerBoundsYang(8)),';]'], 'y',1);
                InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cerp.upper', ['[',num2str(modelInput.cerp.upper(1)),';',num2str(modelInput.cerp.upper(2)),';',num2str(modelInput.cerp.upper(3)),';',num2str(modelInput.cerp.upper(4)),';',num2str(modelInput.cerp.upper(5)),';',num2str(modelInput.cerp.upper(6)),';',num2str(modelInput.cerp.upper(7)),';',num2str(modelInput.cerp.upper(8)),';]'], ['[',num2str(upperBoundsYang(1)),';',num2str(upperBoundsYang(2)),';',num2str(upperBoundsYang(3)),';',num2str(upperBoundsYang(4)),';',num2str(upperBoundsYang(5)),';',num2str(upperBoundsYang(6)),';',num2str(upperBoundsYang(7)),';',num2str(upperBoundsYang(8)),';]'], 'y',1);
            end
        end

        if Options.DykeComparison==1 || (matches(Options.OtherSourceType,'D') && Options.OtherSource ==1)
            if Options.BoundLimits ==1
            [Xlims, Ylims] = boundingbox(FineBoundingBox);
                startBoundsDyke = [Options.DykeStartLength; Options.DykeStartWidth; Options.DykeStartDepth; Options.DykeStartDip; Options.DykeStartStrike; round((mean(Xlims)*Options.SpatialRes));round((mean(Ylims)*Options.SpatialRes)); Options.DykeStartOpening];
                lowerBoundsDyke = [Options.DykeMinLength; Options.DykeMinWidth; Options.DykeMinDepth; Options.DykeMinDip; Options.DykeMinStrike;round((Xlims(1)*Options.SpatialRes));round((Ylims(1)*Options.SpatialRes)); Options.DykeMinOpening];
                upperBoundsDyke = [Options.DykeMaxLength; Options.DykeMaxWidth; Options.DykeMaxDepth; Options.DykeMaxDip; Options.DykeMaxStrike;round((Xlims(2)*Options.SpatialRes));round((Ylims(2)*Options.SpatialRes)); Options.DykeMaxOpening];
            
            elseif Options.BoundLimits ==2
                startBoundsDyke = [Options.DykeStartLength; Options.DykeStartWidth; Options.DykeStartDepth; Options.DykeStartStrike;(MaxCoords/2);(MaxCoords/2);Options.DykeStartOpening];
                lowerBoundsDyke = [Options.DykeMinLength; Options.DykeMinWidth; Options.DykeMinDepth; Options.DykeMinStrike;(MaxCoords*0.05);(MaxCoords*0.05); Options.DykeMinOpening];
                upperBoundsDyke = [Options.DykeMaxLength; Options.DykeMaxWidth; Options.DykeMaxDepth; Options.DykeMaxStrike;(MaxCoords*0.95);(MaxCoords*0.95); Options.DykeMaxOpening];
            end
            
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.dike.start', ['[',num2str(modelInput.dike.start(1)),';',num2str(modelInput.dike.start(2)),';',num2str(modelInput.dike.start(3)),';',num2str(modelInput.dike.start(4)),';',num2str(modelInput.dike.start(5)),';',num2str(modelInput.dike.start(6)),';',num2str(modelInput.dike.start(7)),';',num2str(modelInput.dike.start(8)),';]'], ['[',num2str(startBoundsDyke(1)),';',num2str(startBoundsDyke(2)),';',num2str(startBoundsDyke(3)),';',num2str(startBoundsDyke(4)),';',num2str(startBoundsDyke(5)),';',num2str(startBoundsDyke(6)),';',num2str(startBoundsDyke(7)),';',num2str(startBoundsDyke(8)),';]'], 'y',1);
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.dike.lower', ['[',num2str(modelInput.dike.lower(1)),';',num2str(modelInput.dike.lower(2)),';',num2str(modelInput.dike.lower(3)),';',num2str(modelInput.dike.lower(4)),';',num2str(modelInput.dike.lower(5)),';',num2str(modelInput.dike.lower(6)),';',num2str(modelInput.dike.lower(7)),';',num2str(modelInput.dike.lower(8)),';]'], ['[',num2str(lowerBoundsDyke(1)),';',num2str(lowerBoundsDyke(2)),';',num2str(lowerBoundsDyke(3)),';',num2str(lowerBoundsDyke(4)),';',num2str(lowerBoundsDyke(5)),';',num2str(lowerBoundsDyke(6)),';',num2str(lowerBoundsDyke(7)),';',num2str(lowerBoundsDyke(8)),';]'], 'y',1);
            InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.dike.upper', ['[',num2str(modelInput.dike.upper(1)),';',num2str(modelInput.dike.upper(2)),';',num2str(modelInput.dike.upper(3)),';',num2str(modelInput.dike.upper(4)),';',num2str(modelInput.dike.upper(5)),';',num2str(modelInput.dike.upper(6)),';',num2str(modelInput.dike.upper(7)),';',num2str(modelInput.dike.upper(8)),';]'], ['[',num2str(upperBoundsDyke(1)),';',num2str(upperBoundsDyke(2)),';',num2str(upperBoundsDyke(3)),';',num2str(upperBoundsDyke(4)),';',num2str(upperBoundsDyke(5)),';',num2str(upperBoundsDyke(6)),';',num2str(upperBoundsDyke(7)),';',num2str(upperBoundsDyke(8)),';]'], 'y',1);
        end

        if Options.CDMComparison==1 || ((matches(Options.OtherSourceType,'A')|...
                                        matches(Options.OtherSourceType,'B')|...
                                        matches(Options.OtherSourceType,'G')|...
                                        matches(Options.OtherSourceType,'I')|...
                                        matches(Options.OtherSourceType,'J')|...
                                        matches(Options.OtherSourceType,'K')|...
                                        matches(Options.OtherSourceType,'L')|...
                                        matches(Options.OtherSourceType,'O'))...
                                        && Options.OtherSource ==1)

            if ismember(1,Options.CDMGeometry) || (matches(Options.OtherSourceType,'A') && Options.OtherSource ==1)
                
                if Options.BoundLimits ==1
                    [Xlims, Ylims] = boundingbox(FineBoundingBox);
                    startBoundsCDM = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDMStartZ; Options.CDMStartOmegX; Options.CDMStartOmegY; Options.CDMStartOmegZ; Options.CDMStartAX; Options.CDMStartAY; Options.CDMStartAZ; Options.CDMStartOpen];
                    lowerBoundsCDM = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDMMinZ; Options.CDMMinOmegX; Options.CDMMinOmegY; Options.CDMMinOmegZ; Options.CDMMinAX; Options.CDMMinAY; Options.CDMMinAZ; Options.CDMMinOpen];
                    upperBoundsCDM = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDMMaxZ; Options.CDMMaxOmegX; Options.CDMMaxOmegY; Options.CDMMaxOmegZ; Options.CDMMaxAX; Options.CDMMaxAY; Options.CDMMaxAZ; Options.CDMMaxOpen];

                    % Add these bounds to the .inp input file
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmn.start', ['[',num2str(modelInput.cdmn.start(1)),';',num2str(modelInput.cdmn.start(2)),';',num2str(modelInput.cdmn.start(3)),';',num2str(modelInput.cdmn.start(4)),';',num2str(modelInput.cdmn.start(5)),';',num2str(modelInput.cdmn.start(6)),';',num2str(modelInput.cdmn.start(7)),';',num2str(modelInput.cdmn.start(8)),';',num2str(modelInput.cdmn.start(9)),';',num2str(modelInput.cdmn.start(10)),';]'], ['[',num2str(startBoundsCDM(1)),';',num2str(startBoundsCDM(2)),';',num2str(startBoundsCDM(3)),';',num2str(startBoundsCDM(4)),';',num2str(startBoundsCDM(5)),';',num2str(startBoundsCDM(6)),';',num2str(startBoundsCDM(7)),';',num2str(startBoundsCDM(8)),';',num2str(startBoundsCDM(9)),';',num2str(startBoundsCDM(10)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmn.lower', ['[',num2str(modelInput.cdmn.lower(1)),';',num2str(modelInput.cdmn.lower(2)),';',num2str(modelInput.cdmn.lower(3)),';',num2str(modelInput.cdmn.lower(4)),';',num2str(modelInput.cdmn.lower(5)),';',num2str(modelInput.cdmn.lower(6)),';',num2str(modelInput.cdmn.lower(7)),';',num2str(modelInput.cdmn.lower(8)),';',num2str(modelInput.cdmn.lower(9)),';',num2str(modelInput.cdmn.lower(10)),';]'], ['[',num2str(lowerBoundsCDM(1)),';',num2str(lowerBoundsCDM(2)),';',num2str(lowerBoundsCDM(3)),';',num2str(lowerBoundsCDM(4)),';',num2str(lowerBoundsCDM(5)),';',num2str(lowerBoundsCDM(6)),';',num2str(lowerBoundsCDM(7)),';',num2str(lowerBoundsCDM(8)),';',num2str(lowerBoundsCDM(9)),';',num2str(lowerBoundsCDM(10)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmn.upper', ['[',num2str(modelInput.cdmn.upper(1)),';',num2str(modelInput.cdmn.upper(2)),';',num2str(modelInput.cdmn.upper(3)),';',num2str(modelInput.cdmn.upper(4)),';',num2str(modelInput.cdmn.upper(5)),';',num2str(modelInput.cdmn.upper(6)),';',num2str(modelInput.cdmn.upper(7)),';',num2str(modelInput.cdmn.upper(8)),';',num2str(modelInput.cdmn.upper(9)),';',num2str(modelInput.cdmn.upper(10)),';]'], ['[',num2str(upperBoundsCDM(1)),';',num2str(upperBoundsCDM(2)),';',num2str(upperBoundsCDM(3)),';',num2str(upperBoundsCDM(4)),';',num2str(upperBoundsCDM(5)),';',num2str(upperBoundsCDM(6)),';',num2str(upperBoundsCDM(7)),';',num2str(upperBoundsCDM(8)),';',num2str(upperBoundsCDM(9)),';',num2str(upperBoundsCDM(10)),';]'], 'y',1); 
                elseif Options.BoundLimits ==2
                    startBoundsCDM = [(MaxCoords/2);(MaxCoords/2); Options.CDMStartZ; Options.CDMStartOmegX; Options.CDMStartOmegY; Options.CDMStartOmegZ; Options.CDMStartAX; Options.CDMStartAY; Options.CDMStartAZ; Options.CDMStartOpen];
                    lowerBoundsCDM = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDMMinZ; Options.CDMMinOmegX; Options.CDMMinOmegY; Options.CDMMinOmegZ; Options.CDMMinAX; Options.CDMMinAY; Options.CDMMinAZ; Options.CDMMinOpen];
                    upperBoundsCDM = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDMMaxZ; Options.CDMMaxOmegX; Options.CDMMaxOmegY; Options.CDMMaxOmegZ; Options.CDMMaxAX; Options.CDMMaxAY; Options.CDMMaxAZ; Options.CDMMaxOpen];

                    % Add these bounds to the .inp input file
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmn.start', ['[',num2str(modelInput.cdmn.start(1)),';',num2str(modelInput.cdmn.start(2)),';',num2str(modelInput.cdmn.start(3)),';',num2str(modelInput.cdmn.start(4)),';',num2str(modelInput.cdmn.start(5)),';',num2str(modelInput.cdmn.start(6)),';',num2str(modelInput.cdmn.start(7)),';',num2str(modelInput.cdmn.start(8)),';',num2str(modelInput.cdmn.start(9)),';',num2str(modelInput.cdmn.start(10)),';]'], ['[',num2str(startBoundsCDM(1)),';',num2str(startBoundsCDM(2)),';',num2str(startBoundsCDM(3)),';',num2str(startBoundsCDM(4)),';',num2str(startBoundsCDM(5)),';',num2str(startBoundsCDM(6)),';',num2str(startBoundsCDM(7)),';',num2str(startBoundsCDM(8)),';',num2str(startBoundsCDM(9)),';',num2str(startBoundsCDM(10)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmn.lower', ['[',num2str(modelInput.cdmn.lower(1)),';',num2str(modelInput.cdmn.lower(2)),';',num2str(modelInput.cdmn.lower(3)),';',num2str(modelInput.cdmn.lower(4)),';',num2str(modelInput.cdmn.lower(5)),';',num2str(modelInput.cdmn.lower(6)),';',num2str(modelInput.cdmn.lower(7)),';',num2str(modelInput.cdmn.lower(8)),';',num2str(modelInput.cdmn.lower(9)),';',num2str(modelInput.cdmn.lower(10)),';]'], ['[',num2str(lowerBoundsCDM(1)),';',num2str(lowerBoundsCDM(2)),';',num2str(lowerBoundsCDM(3)),';',num2str(lowerBoundsCDM(4)),';',num2str(lowerBoundsCDM(5)),';',num2str(lowerBoundsCDM(6)),';',num2str(lowerBoundsCDM(7)),';',num2str(lowerBoundsCDM(8)),';',num2str(lowerBoundsCDM(9)),';',num2str(lowerBoundsCDM(10)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmn.upper', ['[',num2str(modelInput.cdmn.upper(1)),';',num2str(modelInput.cdmn.upper(2)),';',num2str(modelInput.cdmn.upper(3)),';',num2str(modelInput.cdmn.upper(4)),';',num2str(modelInput.cdmn.upper(5)),';',num2str(modelInput.cdmn.upper(6)),';',num2str(modelInput.cdmn.upper(7)),';',num2str(modelInput.cdmn.upper(8)),';',num2str(modelInput.cdmn.upper(9)),';',num2str(modelInput.cdmn.upper(10)),';]'], ['[',num2str(upperBoundsCDM(1)),';',num2str(upperBoundsCDM(2)),';',num2str(upperBoundsCDM(3)),';',num2str(upperBoundsCDM(4)),';',num2str(upperBoundsCDM(5)),';',num2str(upperBoundsCDM(6)),';',num2str(upperBoundsCDM(7)),';',num2str(upperBoundsCDM(8)),';',num2str(upperBoundsCDM(9)),';',num2str(upperBoundsCDM(10)),';]'], 'y',1); 
                end
            end

            if ismember(2,Options.CDMGeometry) || (matches(Options.OtherSourceType,'B') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDMB = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_AS_StartZ; Options.CDM_AS_StartAX; Options.CDM_AS_StartDV];
                    lowerBoundsCDMB = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_AS_MinZ; Options.CDM_AS_MinAX; Options.CDM_AS_MinDV];
                    upperBoundsCDMB = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_AS_MaxZ; Options.CDM_AS_MaxAX; Options.CDM_AS_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmb.start', ['[',num2str(modelInput.cdmb.start(1)),';',num2str(modelInput.cdmb.start(2)),';',num2str(modelInput.cdmb.start(3)),';',num2str(modelInput.cdmb.start(4)),';',num2str(modelInput.cdmb.start(5)),';]'], ['[',num2str(startBoundsCDMB(1)),';',num2str(startBoundsCDMB(2)),';',num2str(startBoundsCDMB(3)),';',num2str(startBoundsCDMB(4)),';',num2str(startBoundsCDMB(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmb.lower', ['[',num2str(modelInput.cdmb.lower(1)),';',num2str(modelInput.cdmb.lower(2)),';',num2str(modelInput.cdmb.lower(3)),';',num2str(modelInput.cdmb.lower(4)),';',num2str(modelInput.cdmb.lower(5)),';]'], ['[',num2str(lowerBoundsCDMB(1)),';',num2str(lowerBoundsCDMB(2)),';',num2str(lowerBoundsCDMB(3)),';',num2str(lowerBoundsCDMB(4)),';',num2str(lowerBoundsCDMB(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmb.upper', ['[',num2str(modelInput.cdmb.upper(1)),';',num2str(modelInput.cdmb.upper(2)),';',num2str(modelInput.cdmb.upper(3)),';',num2str(modelInput.cdmb.upper(4)),';',num2str(modelInput.cdmb.upper(5)),';]'], ['[',num2str(upperBoundsCDMB(1)),';',num2str(upperBoundsCDMB(2)),';',num2str(upperBoundsCDMB(3)),';',num2str(upperBoundsCDMB(4)),';',num2str(upperBoundsCDMB(5)),';]'], 'y',1);

                elseif Options.BoundLimits ==2
                    startBoundsCDMB = [(MaxCoords/2);(MaxCoords/2); Options.CDM_AS_StartZ; Options.CDM_AS_StartAX; Options.CDM_AS_StartDV];
                    lowerBoundsCDMB = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_AS_MinZ; Options.CDM_AS_MinAX; Options.CDM_AS_MinDV];
                    upperBoundsCDMB = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_AS_MaxZ; Options.CDM_AS_MaxAX; Options.CDM_AS_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmb.start', ['[',num2str(modelInput.cdmb.start(1)),';',num2str(modelInput.cdmb.start(2)),';',num2str(modelInput.cdmb.start(3)),';',num2str(modelInput.cdmb.start(4)),';',num2str(modelInput.cdmb.start(5)),';]'], ['[',num2str(startBoundsCDMB(1)),';',num2str(startBoundsCDMB(2)),';',num2str(startBoundsCDMB(3)),';',num2str(startBoundsCDMB(4)),';',num2str(startBoundsCDMB(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmb.lower', ['[',num2str(modelInput.cdmb.lower(1)),';',num2str(modelInput.cdmb.lower(2)),';',num2str(modelInput.cdmb.lower(3)),';',num2str(modelInput.cdmb.lower(4)),';',num2str(modelInput.cdmb.lower(5)),';]'], ['[',num2str(lowerBoundsCDMB(1)),';',num2str(lowerBoundsCDMB(2)),';',num2str(lowerBoundsCDMB(3)),';',num2str(lowerBoundsCDMB(4)),';',num2str(lowerBoundsCDMB(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmb.upper', ['[',num2str(modelInput.cdmb.upper(1)),';',num2str(modelInput.cdmb.upper(2)),';',num2str(modelInput.cdmb.upper(3)),';',num2str(modelInput.cdmb.upper(4)),';',num2str(modelInput.cdmb.upper(5)),';]'], ['[',num2str(upperBoundsCDMB(1)),';',num2str(upperBoundsCDMB(2)),';',num2str(upperBoundsCDMB(3)),';',num2str(upperBoundsCDMB(4)),';',num2str(upperBoundsCDMB(5)),';]'], 'y',1);
                end
            end

            if ismember(3,Options.CDMGeometry) || (matches(Options.OtherSourceType,'G') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDMG = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_S_StartAX; Options.CDM_S_StartOmegX; Options.CDM_S_StartOmegZ; Options.CDM_S_StartDV];
                    lowerBoundsCDMG = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_S_MinOmegX; Options.CDM_S_MinOmegZ; Options.CDM_S_MinDV];
                    upperBoundsCDMG = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_S_MaxOmegX; Options.CDM_S_MaxOmegZ; Options.CDM_S_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmg.start', ['[',num2str(modelInput.cdmg.start(1)),';',num2str(modelInput.cdmg.start(2)),';',num2str(modelInput.cdmg.start(3)),';',num2str(modelInput.cdmg.start(4)),';',num2str(modelInput.cdmg.start(5)),';',num2str(modelInput.cdmg.start(6)),';',num2str(modelInput.cdmg.start(7)),';]'], ['[',num2str(startBoundsCDMG(1)),';',num2str(startBoundsCDMG(2)),';',num2str(startBoundsCDMG(3)),';',num2str(startBoundsCDMG(4)),';',num2str(startBoundsCDMG(5)),';',num2str(startBoundsCDMG(6)),';',num2str(startBoundsCDMG(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmg.lower', ['[',num2str(modelInput.cdmg.lower(1)),';',num2str(modelInput.cdmg.lower(2)),';',num2str(modelInput.cdmg.lower(3)),';',num2str(modelInput.cdmg.lower(4)),';',num2str(modelInput.cdmg.lower(5)),';',num2str(modelInput.cdmg.lower(6)),';',num2str(modelInput.cdmg.lower(7)),';]'], ['[',num2str(lowerBoundsCDMG(1)),';',num2str(lowerBoundsCDMG(2)),';',num2str(lowerBoundsCDMG(3)),';',num2str(lowerBoundsCDMG(4)),';',num2str(lowerBoundsCDMG(5)),';',num2str(lowerBoundsCDMG(6)),';',num2str(lowerBoundsCDMG(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmg.upper', ['[',num2str(modelInput.cdmg.upper(1)),';',num2str(modelInput.cdmg.upper(2)),';',num2str(modelInput.cdmg.upper(3)),';',num2str(modelInput.cdmg.upper(4)),';',num2str(modelInput.cdmg.upper(5)),';',num2str(modelInput.cdmg.upper(6)),';',num2str(modelInput.cdmg.upper(7)),';]'], ['[',num2str(upperBoundsCDMG(1)),';',num2str(upperBoundsCDMG(2)),';',num2str(upperBoundsCDMG(3)),';',num2str(upperBoundsCDMG(4)),';',num2str(upperBoundsCDMG(5)),';',num2str(upperBoundsCDMG(6)),';',num2str(upperBoundsCDMG(7)),';]'], 'y',1);
                elseif Options.BoundLimits ==2
                    startBoundsCDMG = [(MaxCoords/2);(MaxCoords/2); Options.CDM_S_StartZ; Options.CDM_S_StartAX; Options.CDM_S_StartOmegX; Options.CDM_S_StartOmegZ; Options.CDM_S_StartDV];
                    lowerBoundsCDMG = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_S_MinZ; Options.CDM_S_MinAX; Options.CDM_S_MinOmegX; Options.CDM_S_MinOmegZ; Options.CDM_S_MinDV];
                    upperBoundsCDMG = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_S_MaxZ; Options.CDM_S_MaxAX; Options.CDM_S_MaxOmegX; Options.CDM_S_MaxOmegZ; Options.CDM_S_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmg.start', ['[',num2str(modelInput.cdmg.start(1)),';',num2str(modelInput.cdmg.start(2)),';',num2str(modelInput.cdmg.start(3)),';',num2str(modelInput.cdmg.start(4)),';',num2str(modelInput.cdmg.start(5)),';',num2str(modelInput.cdmg.start(6)),';',num2str(modelInput.cdmg.start(7)),';]'], ['[',num2str(startBoundsCDMG(1)),';',num2str(startBoundsCDMG(2)),';',num2str(startBoundsCDMG(3)),';',num2str(startBoundsCDMG(4)),';',num2str(startBoundsCDMG(5)),';',num2str(startBoundsCDMG(6)),';',num2str(startBoundsCDMG(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmg.lower', ['[',num2str(modelInput.cdmg.lower(1)),';',num2str(modelInput.cdmg.lower(2)),';',num2str(modelInput.cdmg.lower(3)),';',num2str(modelInput.cdmg.lower(4)),';',num2str(modelInput.cdmg.lower(5)),';',num2str(modelInput.cdmg.lower(6)),';',num2str(modelInput.cdmg.lower(7)),';]'], ['[',num2str(lowerBoundsCDMG(1)),';',num2str(lowerBoundsCDMG(2)),';',num2str(lowerBoundsCDMG(3)),';',num2str(lowerBoundsCDMG(4)),';',num2str(lowerBoundsCDMG(5)),';',num2str(lowerBoundsCDMG(6)),';',num2str(lowerBoundsCDMG(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmg.upper', ['[',num2str(modelInput.cdmg.upper(1)),';',num2str(modelInput.cdmg.upper(2)),';',num2str(modelInput.cdmg.upper(3)),';',num2str(modelInput.cdmg.upper(4)),';',num2str(modelInput.cdmg.upper(5)),';',num2str(modelInput.cdmg.upper(6)),';',num2str(modelInput.cdmg.upper(7)),';]'], ['[',num2str(upperBoundsCDMG(1)),';',num2str(upperBoundsCDMG(2)),';',num2str(upperBoundsCDMG(3)),';',num2str(upperBoundsCDMG(4)),';',num2str(upperBoundsCDMG(5)),';',num2str(upperBoundsCDMG(6)),';',num2str(upperBoundsCDMG(7)),';]'], 'y',1);
                end
            end

            if ismember(4,Options.CDMGeometry) || (matches(Options.OtherSourceType,'I') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDMI = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_Si_StartZ; Options.CDM_Si_StartAX; Options.CDM_Si_StartDV];
                    lowerBoundsCDMI = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_Si_MinZ; Options.CDM_Si_MinAX; Options.CDM_Si_MinDV];
                    upperBoundsCDMI = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_Si_MaxZ; Options.CDM_Si_MaxAX; Options.CDM_Si_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmi.start', ['[',num2str(modelInput.cdmi.start(1)),';',num2str(modelInput.cdmi.start(2)),';',num2str(modelInput.cdmi.start(3)),';',num2str(modelInput.cdmi.start(4)),';',num2str(modelInput.cdmi.start(5)),';]'], ['[',num2str(startBoundsCDMI(1)),';',num2str(startBoundsCDMI(2)),';',num2str(startBoundsCDMI(3)),';',num2str(startBoundsCDMI(4)),';',num2str(startBoundsCDMI(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmi.lower', ['[',num2str(modelInput.cdmi.lower(1)),';',num2str(modelInput.cdmi.lower(2)),';',num2str(modelInput.cdmi.lower(3)),';',num2str(modelInput.cdmi.lower(4)),';',num2str(modelInput.cdmi.lower(5)),';]'], ['[',num2str(lowerBoundsCDMI(1)),';',num2str(lowerBoundsCDMI(2)),';',num2str(lowerBoundsCDMI(3)),';',num2str(lowerBoundsCDMI(4)),';',num2str(lowerBoundsCDMI(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmi.upper', ['[',num2str(modelInput.cdmi.upper(1)),';',num2str(modelInput.cdmi.upper(2)),';',num2str(modelInput.cdmi.upper(3)),';',num2str(modelInput.cdmi.upper(4)),';',num2str(modelInput.cdmi.upper(5)),';]'], ['[',num2str(upperBoundsCDMI(1)),';',num2str(upperBoundsCDMI(2)),';',num2str(upperBoundsCDMI(3)),';',num2str(upperBoundsCDMI(4)),';',num2str(upperBoundsCDMI(5)),';]'], 'y',1);
                elseif Options.BoundLimits ==2
                    startBoundsCDMI = [(MaxCoords/2);(MaxCoords/2); Options.CDM_Si_StartZ; Options.CDM_Si_StartAX; Options.CDM_Si_StartDV];
                    lowerBoundsCDMI = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_Si_MinZ; Options.CDM_Si_MinAX; Options.CDM_Si_MinDV];
                    upperBoundsCDMI = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_Si_MaxZ; Options.CDM_Si_MaxAX; Options.CDM_Si_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmi.start', ['[',num2str(modelInput.cdmi.start(1)),';',num2str(modelInput.cdmi.start(2)),';',num2str(modelInput.cdmi.start(3)),';',num2str(modelInput.cdmi.start(4)),';',num2str(modelInput.cdmi.start(5)),';]'], ['[',num2str(startBoundsCDMI(1)),';',num2str(startBoundsCDMI(2)),';',num2str(startBoundsCDMI(3)),';',num2str(startBoundsCDMI(4)),';',num2str(startBoundsCDMI(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmi.lower', ['[',num2str(modelInput.cdmi.lower(1)),';',num2str(modelInput.cdmi.lower(2)),';',num2str(modelInput.cdmi.lower(3)),';',num2str(modelInput.cdmi.lower(4)),';',num2str(modelInput.cdmi.lower(5)),';]'], ['[',num2str(lowerBoundsCDMI(1)),';',num2str(lowerBoundsCDMI(2)),';',num2str(lowerBoundsCDMI(3)),';',num2str(lowerBoundsCDMI(4)),';',num2str(lowerBoundsCDMI(5)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmi.upper', ['[',num2str(modelInput.cdmi.upper(1)),';',num2str(modelInput.cdmi.upper(2)),';',num2str(modelInput.cdmi.upper(3)),';',num2str(modelInput.cdmi.upper(4)),';',num2str(modelInput.cdmi.upper(5)),';]'], ['[',num2str(upperBoundsCDMI(1)),';',num2str(upperBoundsCDMI(2)),';',num2str(upperBoundsCDMI(3)),';',num2str(upperBoundsCDMI(4)),';',num2str(upperBoundsCDMI(5)),';]'], 'y',1);
                end
            end

            if ismember(5,Options.CDMGeometry) || (matches(Options.OtherSourceType,'J') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDMJ = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_Si2_StartZ; Options.CDM_Si2_StartAX; Options.CDM_Si2_StartAY; Options.CDM_Si2_StartOmegZ; Options.CDM_Si2_StartDV];
                    lowerBoundsCDMJ = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_Si2_MinZ; Options.CDM_Si2_MinAX; Options.CDM_Si2_MinAY; Options.CDM_Si2_MinOmegZ; Options.CDM_Si2_MinDV];
                    upperBoundsCDMJ = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_Si2_MaxZ; Options.CDM_Si2_MaxAX; Options.CDM_Si2_MaxAY; Options.CDM_Si2_MaxOmegZ; Options.CDM_Si2_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmj.start', ['[',num2str(modelInput.cdmj.start(1)),';',num2str(modelInput.cdmj.start(2)),';',num2str(modelInput.cdmj.start(3)),';',num2str(modelInput.cdmj.start(4)),';',num2str(modelInput.cdmj.start(5)),';',num2str(modelInput.cdmj.start(6)),';',num2str(modelInput.cdmj.start(7)),';]'], ['[',num2str(startBoundsCDMJ(1)),';',num2str(startBoundsCDMJ(2)),';',num2str(startBoundsCDMJ(3)),';',num2str(startBoundsCDMJ(4)),';',num2str(startBoundsCDMJ(5)),';',num2str(startBoundsCDMJ(6)),';',num2str(startBoundsCDMJ(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmj.lower', ['[',num2str(modelInput.cdmj.lower(1)),';',num2str(modelInput.cdmj.lower(2)),';',num2str(modelInput.cdmj.lower(3)),';',num2str(modelInput.cdmj.lower(4)),';',num2str(modelInput.cdmj.lower(5)),';',num2str(modelInput.cdmj.lower(6)),';',num2str(modelInput.cdmj.lower(7)),';]'], ['[',num2str(lowerBoundsCDMJ(1)),';',num2str(lowerBoundsCDMJ(2)),';',num2str(lowerBoundsCDMJ(3)),';',num2str(lowerBoundsCDMJ(4)),';',num2str(lowerBoundsCDMJ(5)),';',num2str(lowerBoundsCDMJ(6)),';',num2str(lowerBoundsCDMJ(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmj.upper', ['[',num2str(modelInput.cdmj.upper(1)),';',num2str(modelInput.cdmj.upper(2)),';',num2str(modelInput.cdmj.upper(3)),';',num2str(modelInput.cdmj.upper(4)),';',num2str(modelInput.cdmj.upper(5)),';',num2str(modelInput.cdmj.upper(6)),';',num2str(modelInput.cdmj.upper(7)),';]'], ['[',num2str(upperBoundsCDMJ(1)),';',num2str(upperBoundsCDMJ(2)),';',num2str(upperBoundsCDMJ(3)),';',num2str(upperBoundsCDMJ(4)),';',num2str(upperBoundsCDMJ(5)),';',num2str(upperBoundsCDMJ(6)),';',num2str(upperBoundsCDMJ(7)),';]'], 'y',1);
                elseif Options.BoundLimits ==2
                    startBoundsCDMJ = [(MaxCoords/2);(MaxCoords/2); Options.CDM_Si2_StartZ; Options.CDM_Si2_StartAX; Options.CDM_Si2_StartAY; Options.CDM_Si2_StartOmegZ; Options.CDM_Si2_StartDV];
                    lowerBoundsCDMJ = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_Si2_MinZ; Options.CDM_Si2_MinAX; Options.CDM_Si2_MinAY; Options.CDM_Si2_MinOmegZ; Options.CDM_Si2_MinDV];
                    upperBoundsCDMJ = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_Si2_MaxZ; Options.CDM_Si2_MaxAX; Options.CDM_Si2_MaxAY; Options.CDM_Si2_MaxOmegZ; Options.CDM_Si2_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmj.start', ['[',num2str(modelInput.cdmj.start(1)),';',num2str(modelInput.cdmj.start(2)),';',num2str(modelInput.cdmj.start(3)),';',num2str(modelInput.cdmj.start(4)),';',num2str(modelInput.cdmj.start(5)),';',num2str(modelInput.cdmj.start(6)),';',num2str(modelInput.cdmj.start(7)),';]'], ['[',num2str(startBoundsCDMJ(1)),';',num2str(startBoundsCDMJ(2)),';',num2str(startBoundsCDMJ(3)),';',num2str(startBoundsCDMJ(4)),';',num2str(startBoundsCDMJ(5)),';',num2str(startBoundsCDMJ(6)),';',num2str(startBoundsCDMJ(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmj.lower', ['[',num2str(modelInput.cdmj.lower(1)),';',num2str(modelInput.cdmj.lower(2)),';',num2str(modelInput.cdmj.lower(3)),';',num2str(modelInput.cdmj.lower(4)),';',num2str(modelInput.cdmj.lower(5)),';',num2str(modelInput.cdmj.lower(6)),';',num2str(modelInput.cdmj.lower(7)),';]'], ['[',num2str(lowerBoundsCDMJ(1)),';',num2str(lowerBoundsCDMJ(2)),';',num2str(lowerBoundsCDMJ(3)),';',num2str(lowerBoundsCDMJ(4)),';',num2str(lowerBoundsCDMJ(5)),';',num2str(lowerBoundsCDMJ(6)),';',num2str(lowerBoundsCDMJ(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmj.upper', ['[',num2str(modelInput.cdmj.upper(1)),';',num2str(modelInput.cdmj.upper(2)),';',num2str(modelInput.cdmj.upper(3)),';',num2str(modelInput.cdmj.upper(4)),';',num2str(modelInput.cdmj.upper(5)),';',num2str(modelInput.cdmj.upper(6)),';',num2str(modelInput.cdmj.upper(7)),';]'], ['[',num2str(upperBoundsCDMJ(1)),';',num2str(upperBoundsCDMJ(2)),';',num2str(upperBoundsCDMJ(3)),';',num2str(upperBoundsCDMJ(4)),';',num2str(upperBoundsCDMJ(5)),';',num2str(upperBoundsCDMJ(6)),';',num2str(upperBoundsCDMJ(7)),';]'], 'y',1);
                end
            end

            if ismember(6,Options.CDMGeometry) || (matches(Options.OtherSourceType,'K') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDMK = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_D_StartZ; Options.CDM_D_StartAX; Options.CDM_D_StartAZ; Options.CDM_D_StartOmegZ; Options.CDM_D_StartDV];
                    lowerBoundsCDMK = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_D_MinZ; Options.CDM_D_MinAX; Options.CDM_D_MinAZ; Options.CDM_D_MinOmegZ; Options.CDM_D_MinDV];
                    upperBoundsCDMK = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_D_MaxZ; Options.CDM_D_MaxAX; Options.CDM_D_MaxAZ; Options.CDM_D_MaxOmegZ; Options.CDM_D_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmk.start', ['[',num2str(modelInput.cdmk.start(1)),';',num2str(modelInput.cdmk.start(2)),';',num2str(modelInput.cdmk.start(3)),';',num2str(modelInput.cdmk.start(4)),';',num2str(modelInput.cdmk.start(5)),';',num2str(modelInput.cdmk.start(6)),';',num2str(modelInput.cdmk.start(7)),';]'], ['[',num2str(startBoundsCDMK(1)),';',num2str(startBoundsCDMK(2)),';',num2str(startBoundsCDMK(3)),';',num2str(startBoundsCDMK(4)),';',num2str(startBoundsCDMK(5)),';',num2str(startBoundsCDMK(6)),';',num2str(startBoundsCDMK(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmk.lower', ['[',num2str(modelInput.cdmk.lower(1)),';',num2str(modelInput.cdmk.lower(2)),';',num2str(modelInput.cdmk.lower(3)),';',num2str(modelInput.cdmk.lower(4)),';',num2str(modelInput.cdmk.lower(5)),';',num2str(modelInput.cdmk.lower(6)),';',num2str(modelInput.cdmk.lower(7)),';]'], ['[',num2str(lowerBoundsCDMK(1)),';',num2str(lowerBoundsCDMK(2)),';',num2str(lowerBoundsCDMK(3)),';',num2str(lowerBoundsCDMK(4)),';',num2str(lowerBoundsCDMK(5)),';',num2str(lowerBoundsCDMK(6)),';',num2str(lowerBoundsCDMK(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmk.upper', ['[',num2str(modelInput.cdmk.upper(1)),';',num2str(modelInput.cdmk.upper(2)),';',num2str(modelInput.cdmk.upper(3)),';',num2str(modelInput.cdmk.upper(4)),';',num2str(modelInput.cdmk.upper(5)),';',num2str(modelInput.cdmk.upper(6)),';',num2str(modelInput.cdmk.upper(7)),';]'], ['[',num2str(upperBoundsCDMK(1)),';',num2str(upperBoundsCDMK(2)),';',num2str(upperBoundsCDMK(3)),';',num2str(upperBoundsCDMK(4)),';',num2str(upperBoundsCDMK(5)),';',num2str(upperBoundsCDMK(6)),';',num2str(upperBoundsCDMK(7)),';]'], 'y',1);
                elseif Options.BoundLimits ==2
                    startBoundsCDMK = [(MaxCoords/2);(MaxCoords/2); Options.CDM_D_StartZ; Options.CDM_D_StartAX; Options.CDM_D_StartAZ; Options.CDM_D_StartOmegZ; Options.CDM_D_StartDV];
                    lowerBoundsCDMK = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_D_MinZ; Options.CDM_D_MinAX; Options.CDM_D_MinAZ; Options.CDM_D_MinOmegZ; Options.CDM_D_MinDV];
                    upperBoundsCDMK = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_D_MaxZ; Options.CDM_D_MaxAX; Options.CDM_D_MaxAZ; Options.CDM_D_MaxOmegZ; Options.CDM_D_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmk.start', ['[',num2str(modelInput.cdmk.start(1)),';',num2str(modelInput.cdmk.start(2)),';',num2str(modelInput.cdmk.start(3)),';',num2str(modelInput.cdmk.start(4)),';',num2str(modelInput.cdmk.start(5)),';',num2str(modelInput.cdmk.start(6)),';',num2str(modelInput.cdmk.start(7)),';]'], ['[',num2str(startBoundsCDMK(1)),';',num2str(startBoundsCDMK(2)),';',num2str(startBoundsCDMK(3)),';',num2str(startBoundsCDMK(4)),';',num2str(startBoundsCDMK(5)),';',num2str(startBoundsCDMK(6)),';',num2str(startBoundsCDMK(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmk.lower', ['[',num2str(modelInput.cdmk.lower(1)),';',num2str(modelInput.cdmk.lower(2)),';',num2str(modelInput.cdmk.lower(3)),';',num2str(modelInput.cdmk.lower(4)),';',num2str(modelInput.cdmk.lower(5)),';',num2str(modelInput.cdmk.lower(6)),';',num2str(modelInput.cdmk.lower(7)),';]'], ['[',num2str(lowerBoundsCDMK(1)),';',num2str(lowerBoundsCDMK(2)),';',num2str(lowerBoundsCDMK(3)),';',num2str(lowerBoundsCDMK(4)),';',num2str(lowerBoundsCDMK(5)),';',num2str(lowerBoundsCDMK(6)),';',num2str(lowerBoundsCDMK(7)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmk.upper', ['[',num2str(modelInput.cdmk.upper(1)),';',num2str(modelInput.cdmk.upper(2)),';',num2str(modelInput.cdmk.upper(3)),';',num2str(modelInput.cdmk.upper(4)),';',num2str(modelInput.cdmk.upper(5)),';',num2str(modelInput.cdmk.upper(6)),';',num2str(modelInput.cdmk.upper(7)),';]'], ['[',num2str(upperBoundsCDMK(1)),';',num2str(upperBoundsCDMK(2)),';',num2str(upperBoundsCDMK(3)),';',num2str(upperBoundsCDMK(4)),';',num2str(upperBoundsCDMK(5)),';',num2str(upperBoundsCDMK(6)),';',num2str(upperBoundsCDMK(7)),';]'], 'y',1);
                end
            end

            if ismember(7,Options.CDMGeometry) || (matches(Options.OtherSourceType,'L') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDML = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_PS_StartZ; Options.CDM_PS_StartAZ; Options.CDM_PS_StartAspectRatio; Options.CDM_PS_StartOmegX; Options.CDM_PS_StartOmegZ; Options.CDM_PS_StartDV];
                    lowerBoundsCDML = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_PS_MinZ; Options.CDM_PS_MinAZ; Options.CDM_PS_MinAspectRatio; Options.CDM_PS_MinOmegX; Options.CDM_PS_MinOmegZ; Options.CDM_PS_MinDV];
                    upperBoundsCDML = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_PS_MaxZ; Options.CDM_PS_MaxAZ; Options.CDM_PS_MaxAspectRatio; Options.CDM_PS_MaxOmegX; Options.CDM_PS_MaxOmegZ; Options.CDM_PS_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdml.start', ['[',num2str(modelInput.cdml.start(1)),';',num2str(modelInput.cdml.start(2)),';',num2str(modelInput.cdml.start(3)),';',num2str(modelInput.cdml.start(4)),';',num2str(modelInput.cdml.start(5)),';',num2str(modelInput.cdml.start(6)),';',num2str(modelInput.cdml.start(7)),';',num2str(modelInput.cdml.start(8)),';]'], ['[',num2str(startBoundsCDML(1)),';',num2str(startBoundsCDML(2)),';',num2str(startBoundsCDML(3)),';',num2str(startBoundsCDML(4)),';',num2str(startBoundsCDML(5)),';',num2str(startBoundsCDML(6)),';',num2str(startBoundsCDML(7)),';',num2str(startBoundsCDML(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdml.lower', ['[',num2str(modelInput.cdml.lower(1)),';',num2str(modelInput.cdml.lower(2)),';',num2str(modelInput.cdml.lower(3)),';',num2str(modelInput.cdml.lower(4)),';',num2str(modelInput.cdml.lower(5)),';',num2str(modelInput.cdml.lower(6)),';',num2str(modelInput.cdml.lower(7)),';',num2str(modelInput.cdml.lower(8)),';]'], ['[',num2str(lowerBoundsCDML(1)),';',num2str(lowerBoundsCDML(2)),';',num2str(lowerBoundsCDML(3)),';',num2str(lowerBoundsCDML(4)),';',num2str(lowerBoundsCDML(5)),';',num2str(lowerBoundsCDML(6)),';',num2str(lowerBoundsCDML(7)),';',num2str(lowerBoundsCDML(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdml.upper', ['[',num2str(modelInput.cdml.upper(1)),';',num2str(modelInput.cdml.upper(2)),';',num2str(modelInput.cdml.upper(3)),';',num2str(modelInput.cdml.upper(4)),';',num2str(modelInput.cdml.upper(5)),';',num2str(modelInput.cdml.upper(6)),';',num2str(modelInput.cdml.upper(7)),';',num2str(modelInput.cdml.upper(8)),';]'], ['[',num2str(upperBoundsCDML(1)),';',num2str(upperBoundsCDML(2)),';',num2str(upperBoundsCDML(3)),';',num2str(upperBoundsCDML(4)),';',num2str(upperBoundsCDML(5)),';',num2str(upperBoundsCDML(6)),';',num2str(upperBoundsCDML(7)),';',num2str(upperBoundsCDML(8)),';]'], 'y',1);
                elseif Options.BoundLimits ==2
                    startBoundsCDML = [(MaxCoords/2);(MaxCoords/2); Options.CDM_PS_StartZ; Options.CDM_PS_StartAZ; Options.CDM_PS_StartAspectRatio; Options.CDM_PS_StartOmegX; Options.CDM_PS_StartOmegZ; Options.CDM_PS_StartDV];
                    lowerBoundsCDML = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_PS_MinZ; Options.CDM_PS_MinAZ; Options.CDM_PS_MinAspectRatio; Options.CDM_PS_MinOmegX; Options.CDM_PS_MinOmegZ; Options.CDM_PS_MinDV];
                    upperBoundsCDML = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_PS_MaxZ; Options.CDM_PS_MaxAZ; Options.CDM_PS_MaxAspectRatio; Options.CDM_PS_MaxOmegX; Options.CDM_PS_MaxOmegZ; Options.CDM_PS_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdml.start', ['[',num2str(modelInput.cdml.start(1)),';',num2str(modelInput.cdml.start(2)),';',num2str(modelInput.cdml.start(3)),';',num2str(modelInput.cdml.start(4)),';',num2str(modelInput.cdml.start(5)),';',num2str(modelInput.cdml.start(6)),';',num2str(modelInput.cdml.start(7)),';',num2str(modelInput.cdml.start(8)),';]'], ['[',num2str(startBoundsCDML(1)),';',num2str(startBoundsCDML(2)),';',num2str(startBoundsCDML(3)),';',num2str(startBoundsCDML(4)),';',num2str(startBoundsCDML(5)),';',num2str(startBoundsCDML(6)),';',num2str(startBoundsCDML(7)),';',num2str(startBoundsCDML(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdml.lower', ['[',num2str(modelInput.cdml.lower(1)),';',num2str(modelInput.cdml.lower(2)),';',num2str(modelInput.cdml.lower(3)),';',num2str(modelInput.cdml.lower(4)),';',num2str(modelInput.cdml.lower(5)),';',num2str(modelInput.cdml.lower(6)),';',num2str(modelInput.cdml.lower(7)),';',num2str(modelInput.cdml.lower(8)),';]'], ['[',num2str(lowerBoundsCDML(1)),';',num2str(lowerBoundsCDML(2)),';',num2str(lowerBoundsCDML(3)),';',num2str(lowerBoundsCDML(4)),';',num2str(lowerBoundsCDML(5)),';',num2str(lowerBoundsCDML(6)),';',num2str(lowerBoundsCDML(7)),';',num2str(lowerBoundsCDML(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdml.upper', ['[',num2str(modelInput.cdml.upper(1)),';',num2str(modelInput.cdml.upper(2)),';',num2str(modelInput.cdml.upper(3)),';',num2str(modelInput.cdml.upper(4)),';',num2str(modelInput.cdml.upper(5)),';',num2str(modelInput.cdml.upper(6)),';',num2str(modelInput.cdml.upper(7)),';',num2str(modelInput.cdml.upper(8)),';]'], ['[',num2str(upperBoundsCDML(1)),';',num2str(upperBoundsCDML(2)),';',num2str(upperBoundsCDML(3)),';',num2str(upperBoundsCDML(4)),';',num2str(upperBoundsCDML(5)),';',num2str(upperBoundsCDML(6)),';',num2str(upperBoundsCDML(7)),';',num2str(upperBoundsCDML(8)),';]'], 'y',1);
                end
            end

            if ismember(8,Options.CDMGeometry) || (matches(Options.OtherSourceType,'O') && Options.OtherSource ==1)

                if Options.BoundLimits ==1
                    startBoundsCDMO = [round((mean(Xlims)*Options.SpatialRes)); round((mean(Ylims)*Options.SpatialRes)); Options.CDM_OS_StartZ; Options.CDM_OS_StartAX; Options.CDM_OS_StartAspectRatio; Options.CDM_OS_StartOmegX; Options.CDM_OS_StartOmegZ; Options.CDM_OS_StartDV];
                    lowerBoundsCDMO = [round((Xlims(1)*Options.SpatialRes)); round((Ylims(1)*Options.SpatialRes)); Options.CDM_OS_MinZ; Options.CDM_OS_MinAX; Options.CDM_OS_MinAspectRatio; Options.CDM_OS_MinOmegX; Options.CDM_OS_MinOmegZ; Options.CDM_OS_MinDV];
                    upperBoundsCDMO = [round((Xlims(2)*Options.SpatialRes)); round((Ylims(2)*Options.SpatialRes)); Options.CDM_OS_MaxZ; Options.CDM_OS_MaxAX; Options.CDM_OS_MaxAspectRatio; Options.CDM_OS_MaxOmegX; Options.CDM_OS_MaxOmegZ; Options.CDM_OS_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmo.start', ['[',num2str(modelInput.cdmo.start(1)),';',num2str(modelInput.cdmo.start(2)),';',num2str(modelInput.cdmo.start(3)),';',num2str(modelInput.cdmo.start(4)),';',num2str(modelInput.cdmo.start(5)),';',num2str(modelInput.cdmo.start(6)),';',num2str(modelInput.cdmo.start(7)),';',num2str(modelInput.cdmo.start(8)),';]'], ['[',num2str(startBoundsCDMO(1)),';',num2str(startBoundsCDMO(2)),';',num2str(startBoundsCDMO(3)),';',num2str(startBoundsCDMO(4)),';',num2str(startBoundsCDMO(5)),';',num2str(startBoundsCDMO(6)),';',num2str(startBoundsCDMO(7)),';',num2str(startBoundsCDMO(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmo.lower', ['[',num2str(modelInput.cdmo.lower(1)),';',num2str(modelInput.cdmo.lower(2)),';',num2str(modelInput.cdmo.lower(3)),';',num2str(modelInput.cdmo.lower(4)),';',num2str(modelInput.cdmo.lower(5)),';',num2str(modelInput.cdmo.lower(6)),';',num2str(modelInput.cdmo.lower(7)),';',num2str(modelInput.cdmo.lower(8)),';]'], ['[',num2str(lowerBoundsCDMO(1)),';',num2str(lowerBoundsCDMO(2)),';',num2str(lowerBoundsCDMO(3)),';',num2str(lowerBoundsCDMO(4)),';',num2str(lowerBoundsCDMO(5)),';',num2str(lowerBoundsCDMO(6)),';',num2str(lowerBoundsCDMO(7)),';',num2str(lowerBoundsCDMO(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmo.upper', ['[',num2str(modelInput.cdmo.upper(1)),';',num2str(modelInput.cdmo.upper(2)),';',num2str(modelInput.cdmo.upper(3)),';',num2str(modelInput.cdmo.upper(4)),';',num2str(modelInput.cdmo.upper(5)),';',num2str(modelInput.cdmo.upper(6)),';',num2str(modelInput.cdmo.upper(7)),';',num2str(modelInput.cdmo.upper(8)),';]'], ['[',num2str(upperBoundsCDMO(1)),';',num2str(upperBoundsCDMO(2)),';',num2str(upperBoundsCDMO(3)),';',num2str(upperBoundsCDMO(4)),';',num2str(upperBoundsCDMO(5)),';',num2str(upperBoundsCDMO(6)),';',num2str(upperBoundsCDMO(7)),';',num2str(upperBoundsCDMO(8)),';]'], 'y',1);
                elseif Options.BoundLimits ==2
                    startBoundsCDMO = [(MaxCoords/2);(MaxCoords/2); Options.CDM_OS_StartZ; Options.CDM_OS_StartAX; Options.CDM_OS_StartAspectRatio; Options.CDM_OS_StartOmegX; Options.CDM_OS_StartOmegZ; Options.CDM_OS_StartDV];
                    lowerBoundsCDMO = [(MaxCoords*0.05);(MaxCoords*0.05); Options.CDM_OS_MinZ; Options.CDM_OS_MinAX; Options.CDM_OS_MinAspectRatio; Options.CDM_OS_MinOmegX; Options.CDM_OS_MinOmegZ; Options.CDM_OS_MinDV];
                    upperBoundsCDMO = [(MaxCoords*0.95);(MaxCoords*0.95); Options.CDM_OS_MaxZ; Options.CDM_OS_MaxAX; Options.CDM_OS_MaxAspectRatio; Options.CDM_OS_MaxOmegX; Options.CDM_OS_MaxOmegZ; Options.CDM_OS_MaxDV];

                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmo.start', ['[',num2str(modelInput.cdmo.start(1)),';',num2str(modelInput.cdmo.start(2)),';',num2str(modelInput.cdmo.start(3)),';',num2str(modelInput.cdmo.start(4)),';',num2str(modelInput.cdmo.start(5)),';',num2str(modelInput.cdmo.start(6)),';',num2str(modelInput.cdmo.start(7)),';',num2str(modelInput.cdmo.start(8)),';]'], ['[',num2str(startBoundsCDMO(1)),';',num2str(startBoundsCDMO(2)),';',num2str(startBoundsCDMO(3)),';',num2str(startBoundsCDMO(4)),';',num2str(startBoundsCDMO(5)),';',num2str(startBoundsCDMO(6)),';',num2str(startBoundsCDMO(7)),';',num2str(startBoundsCDMO(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmo.lower', ['[',num2str(modelInput.cdmo.lower(1)),';',num2str(modelInput.cdmo.lower(2)),';',num2str(modelInput.cdmo.lower(3)),';',num2str(modelInput.cdmo.lower(4)),';',num2str(modelInput.cdmo.lower(5)),';',num2str(modelInput.cdmo.lower(6)),';',num2str(modelInput.cdmo.lower(7)),';',num2str(modelInput.cdmo.lower(8)),';]'], ['[',num2str(lowerBoundsCDMO(1)),';',num2str(lowerBoundsCDMO(2)),';',num2str(lowerBoundsCDMO(3)),';',num2str(lowerBoundsCDMO(4)),';',num2str(lowerBoundsCDMO(5)),';',num2str(lowerBoundsCDMO(6)),';',num2str(lowerBoundsCDMO(7)),';',num2str(lowerBoundsCDMO(8)),';]'], 'y',1);
                    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.cdmo.upper', ['[',num2str(modelInput.cdmo.upper(1)),';',num2str(modelInput.cdmo.upper(2)),';',num2str(modelInput.cdmo.upper(3)),';',num2str(modelInput.cdmo.upper(4)),';',num2str(modelInput.cdmo.upper(5)),';',num2str(modelInput.cdmo.upper(6)),';',num2str(modelInput.cdmo.upper(7)),';',num2str(modelInput.cdmo.upper(8)),';]'], ['[',num2str(upperBoundsCDMO(1)),';',num2str(upperBoundsCDMO(2)),';',num2str(upperBoundsCDMO(3)),';',num2str(upperBoundsCDMO(4)),';',num2str(upperBoundsCDMO(5)),';',num2str(upperBoundsCDMO(6)),';',num2str(upperBoundsCDMO(7)),';',num2str(upperBoundsCDMO(8)),';]'], 'y',1);
                end
            end
        end

    end
    
    %% Change noise characteristcs
    if Options.Variogram ==1
        % Populate noise characteristics            
        M = Options.VariogramAttempts; % Large enough to get a representative mean
        Sill = zeros(M,1);
        Range = zeros(M,1);
        Nugget = zeros(M,1);

        FineBoundingBoxLL = convertFineBBcoords(FineBoundingBox,Filename_Raw{j});

        for i = 1:M
            [Sill(i), Range(i), Nugget(i)] = fitVariogram_AOI_Pgon(FineBoundingBoxLL,Filename_Raw{j}, Options.WavelengthM);
        end

        Sill = median(Sill);
        Range = median(Range);
        Nugget = median(Nugget);
    end

    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.dataPath', insar{j}.dataPath, Filename{j}, 'y',j);
    InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.rawDataPath', insar{j}.rawDataPath, Filename_Raw{j}, 'y',j);
    
    if Options.Change_Wavelength ~=0
        % Modify wavelength if needed
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.wavelength', insar{j}.wavelength, Options.Change_Wavelength, 'y',j);
    end

    if Options.Variogram ==0 % Use default values
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.sillExp', 'insar{insarID}', '%insar{insarID}', 'y',j);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.range', 'insar{insarID}', '%insar{insarID}', 'y',j);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.nugget', 'insar{insarID}', '%insar{insarID}', 'y',j);
    elseif Options.Variogram ==1 % use values from variogram iterations
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.sillExp', num2str(insar{j}.sillExp), num2str(Sill), 'y',j);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.range', num2str(insar{j}.range), num2str(Range), 'y',j);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.nugget', num2str(insar{j}.nugget), num2str(Nugget), 'y',j);
    end

    %% Change offset and ramp
    if Options.Offset ==0
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.constOffset', insar{j}.constOffset,'n', 'y',j);
    elseif Options.Offset ==1
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.constOffset', insar{j}.constOffset,'y', 'y',j);

        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.Const.step', num2str(modelInput.Const.step), num2str(Options.OffsetStep), 'y',1);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.Const.lower', num2str(modelInput.Const.lower), num2str(Options.OffsetLower), 'y',1);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.Const.upper', num2str(modelInput.Const.upper), num2str(Options.OffsetUpper), 'y',1);
    end

    if Options.Ramp ==0
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.rampFlag', insar{j}.rampFlag,'n', 'y',j);
    elseif Options.Ramp ==1
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'insar{insarID}.rampFlag', insar{j}.rampFlag,'y', 'y',j);

        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.Ramp.step', num2str(modelInput.Ramp.step), num2str(Options.RampStep), 'y',1);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.Ramp.lower', num2str(modelInput.Ramp.lower), num2str(Options.RampLower), 'y',1);
        InpFilePath = modifyInpFile2(InpFilePath, outputFileName, 'modelInput.Ramp.upper', num2str(modelInput.Ramp.upper), num2str(Options.RampUpper), 'y',1);
    end

    %% Save another input file to be used in a seeding run without an offset
    if Options.SeedingRun ==1
        outputFileNameSeed = strcat(InpFilePath(1:end-4),'_Seed.inp');
        InpFilePathSeed = modifyInpFile2(InpFilePath, outputFileNameSeed, 'insar{insarID}.constOffset', insar{j}.constOffset,'n', 'n',j);
        disp(['Seeding file saved to: ', InpFilePathSeed]);
    end

    disp(['File saved to: ', InpFilePath]);
        
end