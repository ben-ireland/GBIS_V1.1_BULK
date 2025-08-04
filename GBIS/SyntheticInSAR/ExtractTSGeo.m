function [Heading, Incidence] = ExtractTSGeo(TS_Files,auto_angles)

% Ben Ireland, September 2023
% Extract heading and incidence angles from a Sentinel-1 timeseries given the frame ID


if auto_angles ==1
    %Extract frame and generate LiCSAR download link
    Frame = regexp(TS_Files.name, '(?<=_)[0-9AD]{4}_[0-9]{5}_[0-9]{6}(?=.nc)','match');
    FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
    FrameNum = FrameNum;
    
    if startsWith(FrameNum{1},'0') & ~startsWith(FrameNum{1},'00')
        FrameNumMat = cell2mat(FrameNum{1});
        FrameNum{1} = FrameNumMat(2:end);
    elseif startsWith(FrameNum{1},'00')
        FrameNumMat = cell2mat(FrameNum{1});
        FrameNum{1} = FrameNumMat(1:end);
    end

    download_link = char(strcat('https://gws-access.jasmin.ac.uk/public/nceo_geohazards/LiCSAR_products/'...
        ,FrameNum{1},'/',Frame{1},'/metadata/metadata.txt'));

    %Download metadata and extract heading and incidence angle values
    Metadata = webread(download_link);

    head = extractBetween(Metadata,"heading=","avg");
    head = strtrim(head);
    head = str2double(head);

    incidence = extractBetween(Metadata,"avg_incidence_angle=","azimuth");
    incidence = strtrim(incidence);
    incidence = str2double(incidence);
    
else
    head = input('Enter the heading angle for the Sentinel 1 frame of interest');
    incidence = input('Enter the average incidence angle for the Sentinel 1 frame of interest');
end

Heading = head;
Incidence = incidence;
end



