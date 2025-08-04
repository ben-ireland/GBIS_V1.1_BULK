function ReportFilename = CreatePDF_ReportMult(ReportFilePath,OutputFilePath,VolcName,Options)

import mlreportgen.report.* 
import mlreportgen.dom.*

% Create output dirs and filename
if ~exist([pwd,'/PDF_Reports'],'dir')
    mkdir(pwd,'PDF_Reports')
    addpath([pwd,'/PDF_Reports'])
end

disp('Merging PDF report of pre-processing and GBIS results')

% /home/jl20461/GBIS_V1.1_Mod4/Inversion_Results/alu-dalafilla_079D_07694_131313Buffer_ICAV61/invert_1_M/invert_1_M/invert_1_M.mat
load(OutputFilePath);
Patt1 = "/invert_1_" + wildcardPattern + '/';
Patt2 = "/invert_1_" + wildcardPattern + "/invert_1_" + wildcardPattern + "/";

RunName = extractBetween(OutputFilePath,'/Inversion_Results/',Patt1);
RunNum = extractBetween(OutputFilePath,Patt2,'.mat');
OutputReportName = char(strcat(pwd,'/PDF_Reports/',RunName,'_',RunNum));

ReportFilename = [OutputReportName,'.pdf'];
Prep_rpt = Report(OutputReportName,'pdf');

for k = 1:length(insar)
    % Create headings and general info for the report
    ch1 = Chapter();
    ch1.Title =(['Final report for ', [RunName,'_',RunNum]]);
    sec1 = Section;
    sec1.Title = 'General Pre-processing information:';
    para = Paragraph([...
        'Path to downsampled data: ',insar{k}.dataPath]);
    para2 = Paragraph([...
        'Path to original data: ',insar{k}.rawDataPath]);

    if Options.ICA ==1
        para3 = Paragraph('ICA used for denoising');
    else
        para3 = Paragraph('ICA not used for denoising');
    end
    if Options.MaskVolcs ==1
        para4 = Paragraph('Data at nearby volcanoes masked out');
    else
        para4 = Paragraph('Data at nearby volcanoes not masked out');
    end

    para5 = 'Plots of original data from frame(s) used in this modelling run: ';

    image = FormalImage();
    image.Image = [pwd,'/OriginalData/',VolcName{k},'.png'];
    image.Caption = ['Target volcano at the centre of the image'...
                    ,newline,'Image filepath: ', ['/OriginalData/',VolcName{k},'.png']];

    append(sec1,para);
    append(sec1,para2);
    append(sec1,para3);
    append(sec1,para4);
    append(sec1,para5);
    append(sec1,image)
    append(ch1,sec1);

    % Create report from Signal location, ICA and Volcano Masking results
    ch2 = Chapter();
    ch2.Title = 'Pre-processing and downsampling';

    if Options.MaskVolcs ==1
        sec2 = Section;
        sec2.Title = 'Masking nearby volcanoes';
        % /home/jl20461/GBIS_V1.1_Mod4/Buffers/alu-dalafilla_079D_07694_131313_Buffer.png
        if exist([pwd,'/Buffers/',VolcName{k},'_Buffer.png'])==2
            image = FormalImage();
            image.Image = [pwd,'/Buffers/',VolcName{k},'_Buffer.png'];
            image.Caption = ['Black dots = location of masked GVP volcanoes.',...
                ' If no dots, no other GVP volcanoes are in the frame.',...
                newline, 'Image filepath: ', ['/Buffers/',VolcName{k},'_Buffer.png']];
            append(sec2,image);
            append(ch2,sec2);
            clear image
        else
            paraAlt = ['Masking image not found. I searched for: ',[pwd,'/Buffers/',VolcName{k},'_Buffer.png']];
            append(sec2,paraAlt);
            append(ch2,sec2);
        end
    end

    if Options.SlidingWindow ==1
        sec6 = Section;
        sec6.Title = 'Signal location using sliding window approach with region shrinking';
        Para6 = Paragraph('Region shrinking as a pre-processing step before sliding window to remove areas of poor unwrapping');
        if exist([pwd,'/SignalLocation/',VolcName{k},'_RegionShrink.png'])==2
            image = FormalImage();
            image.Image = [pwd,'/SignalLocation/',VolcName{k},'_RegionShrink.png'];
            image.Caption = ['Before (left) and after (right) applying region shrinking on edges of incoherent areas.',...
                newline, 'Image filepath: ', ['/SignalLocation/',VolcName{k},'_RegionShrink.png']];
            append(sec6,Para6);
            append(sec6,image);
            clear image
        else
            paraAlt = ['Sliding window image not found. I searched for: ',[pwd,'/SignalLocation/',VolcName{k},'_RegionShrink.png']];
            append(sec6,paraAlt);
        end


        Para66 = Paragraph('Maximum region over a range of window sizes is computed, the locations are then clustered with DBSCAN and biggest cluster taken');
        if exist([pwd,'/SignalLocation/',VolcName{k},'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'.png'])==2
            image = FormalImage();
            image.Image = [pwd,'/SignalLocation/',VolcName{k},'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'.png'];
            image.Caption = ['Clustering and sliding window results (signal located in polygon on right-hand plot).',...
                newline, 'Image filepath: ', ['/SignalLocation/',VolcName{k},'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'.png']];
            append(sec6,Para66);
            append(sec6,image);
            append(ch2,sec6);
            clear image
        else
            paraAlt = ['Sliding window image 2 not found. I searched for: ',[pwd,'/SignalLocation/',VolcName{k},'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'.png']];
            append(sec6,paraAlt);
            append(ch2,sec6);
        end
    end


    if Options.ICA ==1
        sec3 = Section;
        sec3.Title = 'Independent Component Analysis (ICA) for denoising';

        if exist([pwd,'/ICA/ICA_',VolcName{k},'.png'])==2
            Para1 = Paragraph('RMS is given in mm for ease of reading, whereas the plots show LOS displacement in m for consistency');
            append(sec3,Para1)
            % /home/jl20461/GBIS_V1.1_Mod4/ICA/ICA_alu-dalafilla_079D_07694_131313.png
            image = FormalImage();
            image.Image = [pwd,'/ICA/ICA_',VolcName{k},'.png'];
            image.Caption = ['ICA results (FastICA algorithm)',...
                newline, 'Image filepath: ', ['/ICA/ICA_',VolcName{k},'.png']];
            append(sec3,image);
            clear image
        else
            paraAlt = ['ICA image 1 not found. I searched for: ',[pwd,'/ICA/ICA_',VolcName{k},'.png']];
            append(sec3,paraAlt);
        end

        if exist([pwd,'/ICA/ICA_',VolcName{k},'_',Options.RunID,'Comparison.png'])==2
        image = FormalImage();
        image.Image = [pwd,'/ICA/ICA_',VolcName{k},'_',Options.RunID,'Comparison.png'];
        image.Caption = ['ICA results (FastICA algorithm)',...
            newline, 'Image filepath: ', ['/ICA/ICA_',VolcName{k},'_',Options.RunID,'Comparison.png']];
        append(sec3,image);
        clear image
        append(ch2,sec3);
        else
            paraAlt = ['ICA image 2 not found. I searched for: ',[pwd,'/ICA/ICA_',VolcName{k},'_',Options.RunID,'Comparison.png']];
            append(sec3,paraAlt);
            append(ch2,sec3);
        end
    end    

    % Create report for Otsu downsampling results
    load(insar{k}.rawDataPath)
    Extra = '';

    sec4 = Section;
    sec4.Title = 'Otsu-based downsampling results';
    para = Paragraph(['Original number of datapoints: ',num2str(length(Phase)),...
        ', Number of downsampled datapoints: ', num2str(nObs),...
         ', Downsampling factors (coarse:fine): ', num2str(geo.SS_Factor),':',num2str(geo.SS_FactorF)]);
    append(sec4,para)

    if Options.MaskVolcs ==1
        Extra = append(Extra,'_MaskVolc');
    end
    if Options.ICA ==1
        Extra = append(Extra,'_ICA');
    end

    if exist([pwd,'/Bounding_Boxes/',VolcName{k},'GrayIfg_Shape_2','_',Options.RunID,Extra,'.png'])==2
        image = FormalImage();
        image.Image = [pwd,'/Bounding_Boxes/',VolcName{k},'GrayIfg_Shape_2','_',Options.RunID,Extra,'.png'];
        image.Caption = ['Grayscale image used as input for Otsu-thresholding.',...
            newline, 'Image filepath: ', ['/Bounding_Boxes/',VolcName{k},'GrayIfg_Shape_2','_',Options.RunID,Extra,'.png']];
        append(sec4,image);
        clear image
    else
        paraAlt = ['Otsu downsampling figure 1 not found. I searched for: ',[pwd,'/Bounding_Boxes/',VolcName{k},'GrayIfg_Shape_2','_',Options.RunID,Extra,'.png']];
        append(sec4,paraAlt);
    end

    % /home/jl20461/GBIS_V1.1_Mod4/Bounding_Boxes/alu-dalafilla_079D_07694_131313GrayIfg_Shape_2_MaskVolc_ICA.png
    if exist([pwd,'/Bounding_Boxes/',VolcName{k},'OtsuFig_Shape_2','_',Options.RunID,Extra,'.png'])==2
        image = FormalImage();
        image.Image = [pwd,'/Bounding_Boxes/',VolcName{k},'OtsuFig_Shape_2','_',Options.RunID,Extra,'.png'];
        image.Caption = ['Otsu downsampling results. Spatial parameters of signal  location are here are initial guesses. Revised spatial',...
            ' parameters given in GBIS results section.',newline, 'Image filepath: ', ['/Bounding_Boxes/',VolcName{k},'OtsuFig_Shape_2','_',Options.RunID,Extra,'.png']];
        append(sec4,image);
        clear image
    else
        paraAlt = ['Otsu downsampling figure 2 not found. I searched for: ',[pwd,'/Bounding_Boxes/',VolcName{k},'OtsuFig_Shape_2','_',Options.RunID,Extra,'.png']];
        append(sec4,paraAlt);
    end

    if exist([pwd,'/Bounding_Boxes/',VolcName{k},'OtsuDSFig_Shape_2',Extra,'_',Options.RunID,'.png'])==2
        image = FormalImage();
        image.Image = [pwd,'/Bounding_Boxes/',VolcName{k},'OtsuDSFig_Shape_2',Extra,'_',Options.RunID,'.png'];
        image.Caption = ['Before and after Otsu downsampling showing bounding box location.',...
            newline, 'Image filepath: ', ['/Bounding_Boxes/',VolcName{k},'OtsuDSFig_Shape_2',Extra,'_',Options.RunID,'.png']];
        append(sec4,image);
        clear image
        append(ch2,sec4);
    else
        paraAlt = ['Otsu downsampling figure 3 not found. I searched for: ',[pwd,'/Bounding_Boxes/',VolcName{k},'OtsuDSFig_Shape_2',Extra,'_',Options.RunID,'.png']];
        append(sec4,paraAlt);
        append(ch2,sec4);
    end

    % Create report for temporal results
    sec5 = Section;
    sec5.Title = 'Temporal parameters - function fitting';

    % /home/jl20461/GBIS_V1.1_Mod4/Temporal_Parameters/TS_Fit_alu-dalafilla_079D_07694_131313.png
    if exist([pwd,'/Temporal_Parameters/TS_Fit_',VolcName{k},'.png'])==2
        image = FormalImage();
        image.Image = [pwd,'/Temporal_Parameters/TS_Fit_',VolcName{k},'.png'];
        image.Caption = ['Sigmoidal and linear function fits. Signal location (x,y) derived from Sliding Window + Clustering process.',...
            newline, 'Image filepath: ', ['/Temporal_Parameters/TS_Fit_',VolcName{k},'.png']];
        append(sec5,image);
        append(ch2,sec5);
        clear image
    else
        paraAlt = ['Temporal parameters figure not found. I searched for: ',[pwd,'/Temporal_Parameters/TS_Fit_',VolcName{k},'.png']];
        append(sec5,paraAlt);
        append(ch2,sec5);
    end
    append(Prep_rpt,ch1);
    append(Prep_rpt,ch2);
end

close(Prep_rpt);

% Load PDF report file from GBIS
GBISReport = ReportFilePath;

% Combine PDFs 
mergePdfs({ReportFilename, GBISReport}, ReportFilename);
end