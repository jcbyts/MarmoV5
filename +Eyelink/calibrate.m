function tracker_info = calibrate(tracker_info)
%pds.eyelink.calibrate    start eyelink calibration routines
% p = eyelink.calibrate(p)
%
% Run basic eyelink calibration sequence, using pldaps to present stimuli (via PTB)
% and send/receive communication from Eyelink.
%
% [p]  structure (should be currently running/paused)
%
% All relevant subfunctions located in eyelink.cal
%
% 12/12/2013 jly  adapted from EyelinkDoTrackerSetup.m
% 2017-11-02 TBC  Remove dependency on ".stimulus" field for fixdotW size
%                 Added .trialSetup of reward structures to prevent error (via pds.behavior.reward.trialSetup)
%

commandwindow
% if tracker_info.sound_use
%     sounds(2, 0.2);
% end

disp('*************************************')
disp('Beginning Eyelink Toolbox Calibration')
disp('*************************************')
disp('Checking if Eyelink is recording')


if Eyelink('CheckRecording')==0
    disp('Eyelink is currently recording');
else
    disp('Eyelink is not recording. Is it supposed to be');
end

mytext = 'Control Keys are:\rc\tcalibrate mode\rv\tvalidate\rd\tdrift correction\renter\tcamera setup\resc\texit\r';
fprintf(mytext)

if nargin < 1
    error( 'USAGE: result=EyelinkDoTrackerSetup(el [,sendkey])' );
end
ListenChar(2)

Eyelink( 'StartSetup' );		% start setup mode
Eyelink( 'WaitForModeReady', tracker_info.setup.waitformodereadytime );  % time for mode change


key = 1;
while key~= 0
    key = EyelinkGetKey(tracker_info.setup);		% dump old keys
end

stop = 0;
while stop==0 && bitand(Eyelink( 'CurrentMode'), tracker_info.setup.IN_SETUP_MODE)
    
    i = Eyelink( 'CurrentMode');
    
    if ~Eyelink( 'IsConnected' )
        stop = 1;
    end
    
    if bitand(i, tracker_info.setup.IN_TARGET_MODE)			% calibrate, validate, etc: show targets
        fprintf ('%s\n', 'dotrackersetup: in targetmodedisplay' );
        Eyelink.cal.targetModeDisplay(tracker_info);
    elseif bitand(i, tracker_info.setup.IN_IMAGE_MODE)		% display image until we're back
        fprintf ('%s\n', 'EyelinkDoTrackerSetup: in ''ImageModeDisplay''' );
        Eyelink.cal.clearDisplay(tracker_info);
        
    end
    
    [key, tracker_info.setup] = EyelinkGetKey(tracker_info.setup);		% getkey() HANDLE LOCAL KEY PRESS
    if 1 && key~=0 && key~=tracker_info.setup.JUNK_KEY    % print pressed key codes and chars
        fprintf('%d\t%s\n', key, char(key) );
    end
    
    switch key
        case tracker_info.setup.TERMINATE_KEY				% breakout key code
            return;
        case { 0, tracker_info.setup.JUNK_KEY }          % No or uninterpretable key
        case tracker_info.setup.ESC_KEY
            stop = 1;
        otherwise 		% Echo to tracker for remote control
            if tracker_info.setup.allowlocalcontrol==1
                Eyelink('SendKeyButton', double(key), 0, tracker_info.setup.KB_PRESS );
            end
    end
end % while IN_SETUP_MODE

Eyelink.cal.clearDisplay(tracker_info);	% exit_cal_display()

Eyelink('StartRecording');
Eyelink( 'WaitForModeReady', tracker_info.setup.waitformodereadytime);  % time for mode change

ListenChar(0)
% ShowCursor
return;
end