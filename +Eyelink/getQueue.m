function tracker_info = getQueue(tracker_info)
%eyelink.getQueue gets data samples from eyelink
%
% p = eyelink.getQueue(p)
% eyelink.getQueue pulls the values from the current Eyelink queue and
% puts them into samples and events

if tracker_info.eyelink_use
    
    %get them all
    while ~tracker_info.drained
        if tracker_info.collectQueue
            [samplesIn,eventsIn, tracker_info.drained] = Eyelink('GetQueuedData');
        else
            sample = Eyelink('NewestFloatSample');
            if ~isstruct(sample)
                samplesIn = [];
            else
                samplesIn = [sample.time sample.type sample.flags sample.px sample.py sample.hx sample.hy sample.pa sample.gx sample.gy sample.rx sample.ry sample.status sample.input sample.buttons sample.htype sample.hdata]';
            end
            eventsIn = [];
            tracker_info.drained = true;
        end
        % Get Eyelink samples
        if ~isempty(samplesIn)
            tracker_info.samples(:,(tracker_info.sampleNum+1):tracker_info.sampleNum + size(samplesIn,2)) = samplesIn;
            tracker_info.sampleNum = tracker_info.sampleNum + size(samplesIn,2);
        end
        
        % Get Eyelink events
        if ~isempty(eventsIn)
            tracker_info.events(:,(tracker_info.eventNum+1):tracker_info.eventNum + size(eventsIn,2)) = eventsIn;
            tracker_info.eventNum = tracker_info.eventNum + size(eventsIn,2);
        end
        
        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        %         if tracker_info.collectQueue && (~isempty(samplesIn) || ~isempty(eventsIn))
        %             tracker_info.drained = false;
        %         end
        
    end
    tracker_info.drained = false;
end
end