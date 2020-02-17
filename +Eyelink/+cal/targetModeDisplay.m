function result = targetModeDisplay(tracker_info)
% function result = eyelink.cal.targetModeDisplay(p)
% set eyelink into target mode
%



targetvisible = 0;	% target currently drawn


tx = tracker_info.setup.MISSING;
ty = tracker_info.setup.MISSING;

otx = tracker_info.setup.MISSING;    % current target position
oty = tracker_info.setup.MISSING;

Eyelink.cal.clearDisplay(tracker_info);	% setup_cal_display()

key = 1;
while key~= 0
    [key, tracker_info.setup] = EyelinkGetKey(tracker_info.setup);		% dump old keys
end
% LOOP WHILE WE ARE DISPLAYING TARGETS
stop = 0;
while stop==0 && bitand(Eyelink('CurrentMode'), tracker_info.setup.IN_TARGET_MODE)
    
    if Eyelink( 'IsConnected' )==tracker_info.setup.notconnected
        result = -1;
        return;
    end
    
    [key, tracker_info.setup] = EyelinkGetKey(tracker_info.setup);		% getkey() HANDLE LOCAL KEY PRESS
    
    switch key
        case tracker_info.setup.TERMINATE_KEY       % breakout key code
            Eyelink.cal.clearDisplay(tracker_info);
            result = tracker_info.setup.TERMINATE_KEY;
            return;
        case tracker_info.setup.SPACE_BAR	         		% 32: accept fixation
            if tracker_info.setup.allowlocaltrigger==1
                Eyelink( 'AcceptTrigger');
            end
            break;
        case { 0,  tracker_info.setup.JUNK_KEY	}	% No key
        case tracker_info.setup.ESC_KEY
            if Eyelink('IsConnected') == tracker_info.setup.dummyconnected
                stop=1;
            end
            if tracker_info.setup.allowlocalcontrol==1
                Eyelink('SendKeyButton', key, 0, tracker_info.setup.KB_PRESS );
            end
        otherwise          % Echo to tracker for remote control
            if tracker_info.setup.allowlocalcontrol==1
                Eyelink('SendKeyButton', key, 0, tracker_info.setup.KB_PRESS );
            end
    end % switch key
    
    
    % HANDLE TARGET CHANGES
    [result, tx, ty] = Eyelink( 'TargetCheck');
    
    
    % erased or moved: erase target
    if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
        Eyelink.cal.eraseTarget(tracker_info, tx,ty);
        targetvisible = 0;
    end
    % redraw if invisible
    if targetvisible==0 && result==1
        fprintf( 'Target drawn at: x=%d, y=%d\n', tx, ty );
        
        Eyelink.cal.drawTarget(tracker_info, tx, ty);
        targetvisible = 1;
        otx = tx;		% record position for future tests
        oty = ty;
        if tracker_info.setup.targetbeep==1 && tracker_info.sound_use
            EyelinkCalTargetBeep(tracker_info);	% optional beep to alert subject
        end
    end
    
end % while IN_TARGET_MODE


% exit:					% CLEAN UP ON EXIT
if tracker_info.setup.targetbeep==1 && tracker_info.sound_use
    if Eyelink('CalResult')==1  % does 1 signal success?
        EyelinkCalDoneBeep(tracker_info, 1);
    else
        EyelinkCalDoneBeep(tracker_info, -1);
    end
end

if targetvisible==1
    Eyelink.cal.eraseTarget(tracker_info, tx,ty);   % erase target on exit, bit superfluous actually
end
Eyelink.cal.clearDisplay(tracker_info);

result = 0;
return;
