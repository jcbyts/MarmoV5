function init()
%initialize Datapixx at the beginning of an experiment.
% this is really a barebones version until I can figure out everything
% PLDAPS is using it to do, JM 10/7/2018

% datapixx.init()
%
% datapixx.init is a function that intializes the DATAPIXX, preparing it for
% experiments. 

    if ~Datapixx('IsReady')
        Datapixx('Open');
    end
    
    % From help PsychDataPixx:
    % Timestamping is disabled by default (mode == 0), as it incurs a bit of
    % computational overhead to acquire and log timestamps, typically up to 2-3
    % msecs of extra time per 'Flip' command.
    % Buffer is collected at the end of the expeiment!
    PsychDataPixx('LogOnsetTimestamps',0); 
    PsychDataPixx('ClearTimestampLog');
       
    %%% Open Datapixx and get ready for data aquisition %%%
    Datapixx('StopAllSchedules');
    Datapixx('DisableDinDebounce');
    Datapixx('EnableAdcFreeRunning');
    Datapixx('SetDinLog');
    Datapixx('StartDinLog');
    Datapixx('SetDoutValues',0);
    Datapixx('RegWrRd');
end
