function tracker_info = startTrial(tracker_info)
%eyelink.startTrial    allocate and clear buffer for the next trial
%
% allocates the data structs and also clears the buffer
%
% p = startTrial(p)

if tracker_info.eyelink_use
    tracker_info.sampleNum = 0;
    tracker_info.eventNum = 0;
    tracker_info.drained = false; % drained is a flag for pulling from the buffer
    if ischar(tracker_info.srate)
        tracker_info.srate = str2double(tracker_info.srate); 
    end
    tracker_info.samples  = [];
    tracker_info.events   = [];
    
    
    % Pre clear buffer
    if Eyelink('CheckRecording')~=0
        Eyelink('StartRecording')
    end
end
 