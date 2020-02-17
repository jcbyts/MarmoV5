function [tracker_info, broke_condition, loc, temp_length] = track_eye(tracker_info, temp_length, location, duration, allowblink, check_status)
% This function tracks and returns the position of the eye of interest. It
% also returns if the position is in the location boundary using isFixation
% function.
if strcmpi(check_status,'is_fixating')
    loc = location;
    tstart = GetSecs();
    broke_condition = 0;
    % reference time for when while loop starts.
    if tracker_info.eyelink_use
        reference = temp_length;
    end
    while GetSecs() - tstart < duration
        % If eyelink_use is true, track the position of the eye.
        if tracker_info.eyelink_use
            tracker_info = Eyelink.getQueue(tracker_info);
            temp_length = length(tracker_info.samples(tracker_info.eyeIdx+13,:));
            
        end
        [eyex, eyey , ~] = Eyelink.getGazePoint(tracker_info);
        % Computing if the gaze is in fixation boundary.
        [fixation] = Eyelink.isFixation(tracker_info.pre_fixationRadius, [eyex eyey],location, allowblink);
        if ~fixation
            broke_condition=1;
            return;
        end
    end
    
    % To prevent broke_condition = 1 when there is no signal (-32768) from eyelink
    % during the 'while loop.'
    
    if tracker_info.eyelink_use
        
        if all(tracker_info.samples(tracker_info.eyeIdx+13,reference+1:temp_length)==-32768) && all(tracker_info.samples(tracker_info.eyeIdx+15,reference+1:temp_length)==-32768)
            broke_condition = 1;
            
            return;
        end       
    end
        
elseif strcmpi(check_status,'saccading')
    tstart = GetSecs();
    broke_condition = 1;
    reference=temp_length;
    while GetSecs() - tstart < duration
        if tracker_info.eyelink_use
            tracker_info = Eyelink.getQueue(tracker_info);
        end
        [eyex, eyey , ~] = Eyelink.getGazePoint(tracker_info);
        % Checking where the saccade landed between the two possible
        % periphery locations.
        for l=1:size(location,1)
            [fixation(l)] = Eyelink.isFixation(tracker_info.fixationRadius, [eyex eyey],location(l,:), allowblink);
        end
        loc = location(randi(size(location,1),1),:);
        % if saccade was landed on either the possible locations,
        % broke_codition is false.
        if sum(fixation)>0
            broke_condition = 0;
            loc = location(fixation==1,:);
            % storing location where saccade landed based on the fixatino 1
            % or fixation 2 values.
            return;
        end
        
        % To prevent broke_condition = 1 when there is no signal (-32768) from eyelink
        % during the 'while loop.'
    end
    
    if tracker_info.eyelink_use
        if all(tracker_info.samples(tracker_info.eyeIdx+13,reference+1:temp_length)==-32768) && all(tracker_info.samples(tracker_info.eyeIdx+15,reference+1:temp_length)==-32768)
            broke_condition = 1;
            return;
        end
        
    end
    
end
end
