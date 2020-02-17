function getFiles(tracker_info,filename)
%eyelink.getFiles    transfer from from eyelink to this machine
if nargin<2
    datadir = tracker_info.edfFileLocation;
    file = tracker_info.edfFile;
else
    datadir = tracker_info.edfFileLocation;
    file = filename;
end
Eyelink('Initialize');

result = Eyelink('Receivefile', file, fullfile(datadir,file));
if(result==-1)
    warning('pds:EyelinkGetFiles', ['receiving ' file '.edf failed!'])   
else
    disp(['Files received: ' file '.edf .'])
end
end


