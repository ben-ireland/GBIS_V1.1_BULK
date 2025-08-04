function [VolcanoName, Metadata] = ExtractVolcName(TS_Files)

% Load Sentinel 1 datacube
%Extract frame and generate LiCSAR download link
Frame = regexp(TS_Files.name, '(?<=_)[0-9AD]{4}_[0-9]{5}_[0-9]{6}(?=.nc)','match');
FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');

TrackID = Frame{1}(4);
if TrackID == 'D'
    Track = 'Descending';
elseif TrackID == 'A'
    Track = 'Ascending';
end
    
if startsWith(FrameNum{1},'0')
    FrameNumMat = cell2mat(FrameNum{1});
    FrameNum{1} = FrameNumMat(2:end);
end

VolcanoName = regexp(TS_Files.name,'\S*(?=_[0-9AD]{4}_)','match');

Metadata.TrackID = TrackID;
Metadata.Track = Track;
Metadata.Frame = Frame;
Metadata.FrameNum = FrameNum;
