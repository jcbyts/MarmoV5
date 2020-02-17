function tracker_info = startTrialPrepare(tracker_info)
%eyelink.startTrialPrepare   prepare the next trial
%
% gets and eylink time estimate and send a TRIALSTART message to eyelink
%
% p = startTrialPrepare(p)

if tracker_info.eyelink_use
    tracker_info.eyelinkStartTime = Eyelink.getPreciseTime(6.5e-5,0.1,2);
    Eyelink('message', 'TRIALSTART');
end
 