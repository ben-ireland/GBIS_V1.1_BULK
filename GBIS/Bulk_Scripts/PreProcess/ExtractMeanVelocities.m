function MeanVel = ExtractMeanVelocities(TS_Files, VolcName, Options)

    pattern = '^(.*)/[^/]+$';
    pattern_alt = '^(.*)/[^\]+$';
    
    VolcFolder = regexp(TS_Files.folder, pattern, 'tokens');
    
    if isempty(VolcFolder)
        VolcFolder = regexp(TS_Files.folder, pattern_alt, 'tokens');
    end

    % Check if the match is found and append '/tif/*.unw'
    ExtUnw = '/tif/*.geo.unw.tif';
    ExtUnw2 = extractAfter(ExtUnw,'*');
    if ~isempty(VolcFolder)
        VolcFolder = [VolcFolder{1}{1} ExtUnw];
    else
        VolcFolder = '';
    end

    numImg=0;
    VolcFolders = dir(VolcFolder);
    disp('Extracting velocities from unw tiffs')
    for k = 1:length(VolcFolders)
        if endsWith(num2str(k),'50') || endsWith(num2str(k),'00')
            disp([num2str(k), ' out of ', num2str(length(VolcFolders))]);
        end
        TempName = extractBefore(VolcFolders(k).name,'20');
        Dates = extractBetween(VolcFolders(k).name,TempName,ExtUnw2);
        Dates = strsplit(Dates{1},'_');

        Date1 = datetime(Dates{1}, 'InputFormat', 'yyyyMMdd');
        Date2 = datetime(Dates{2}, 'InputFormat', 'yyyyMMdd');

        % Calculate the difference in days
        day_difference = days(Date2 - Date1);

        UnwFilename = strcat(VolcFolders(k).folder,'/',VolcFolders(k).name);

        [A,~] = readgeoraster(UnwFilename);

        if k==1
            Vels = zeros(size(A));
        end

        if nnz(A(:))./numel(A) > 0.99
            numImg = numImg + 1;
            A(A==0) = NaN;
            Vels = Vels + (A.*(day_difference./365));
        end
    end

    MeanVel = Vels./numImg;
    Filt_MeanVel = medfilt2(MeanVel,[9 9]);

    f = figure();
    subplot(1,2,1)
    imagesc(Filt_MeanVel,'AlphaData',~isnan(Filt_MeanVel));
    axis image
    subplot(1,2,2)
    imagesc(MeanVel,'AlphaData',~isnan(MeanVel));
    colorbar;
    axis image
    saveas(f,'TestVelocities.png');

