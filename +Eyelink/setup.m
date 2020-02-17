function tracker_info = setup(tracker_info,filename,filedir)%, wPtr, display_ppd,sound_use,winRect,viewdist,widthcm,heightcm)
%eyelink.setup    setup eyelink at the beginning of an experiment
%
% p = eyelink.setup(p)

if tracker_info.eyelink_use
    
%     fprintLineBreak;
    fprintf('\tSetting up EYELINK Toolbox for eyetrace. \n');
%     fprintLineBreak;
    
    
    Eyelink('Initialize');
    
    tracker_info.setup = EyelinkInitDefaults(); % don't pass in the window pointer or you can mess up the color range
    if nargin<2
        tracker_info.edfFile = datestr(datetime(now,'ConvertFrom','datenum'), 'mmddHHMM');%datestr(p.trial.session.initTime, 'mmddHHMM');
        tracker_info.edfFileLocation = pwd;
        fprintf('EDFFile: %s\n', tracker_info.edfFile );
    else
        tracker_info.edfFile = filename;
        tracker_info.edfFileLocation = filedir;
    end
    tracker_info.setup.window = tracker_info.wPtr;
    tracker_info.setup.displayCalResults = 1;
    
    EyelinkUpdateDefaults(tracker_info.setup);
    
    % check if eyelink initializes
    if ~Eyelink('IsConnected')
        fprintf('****************************************************************\r')
        fprintf('****************************************************************\r')
        fprintf('Eyelink Init aborted. Eyelink is not connected.\n');
        fprintf('NOT using EYELINK Toolbox for eyetrace. \r')
        fprintf('if you want to use EYELINK Toolbox for your eyetracking needs, \rtry Eyelink(''Shutdown'') and then retry p = pds.eyelink.setup(p)\r')
        
        if tracker_info.sound_use
            Beeper(500); Beeper(400)
        end
        disp('PRESS ENTER TO CONFIRM YOU READ THIS MESSAGE'); pause
        Eyelink('Shutdown')
        tracker_info.eyelink_use = 0;
        return
    end
    
    % open file to record data to
    res = Eyelink('OpenFile', tracker_info.edfFile);
    if res~=0
        fprintf('Cannot create EDF file ''%s'' ', tracker_info.edfFile);
        Eyelink('Shutdown')
        return;
    end
    
    % Eyelink commands to setup the eyelink environment
    datestr(now);
    Eyelink('command',  ['add_file_preamble_text ''Recorded'  '''']);
    Eyelink('command',  'screen_pixel_coords = %ld, %ld, %ld, %ld', tracker_info.winRect(1), tracker_info.winRect(2), tracker_info.winRect(3)-1, tracker_info.winRect(4)-1);
    Eyelink('command',  'analog_dac_range = %1d, %1d', -5, 5);
    w = round(10 * tracker_info.widthcm / 2);
    h = round(10 * tracker_info.heightcm / 2);
    Eyelink('command',  'screen_phys_coords = %1d, %1d, %1d, %1d', -w, h, w, -h);
    Eyelink('command',  'screen_distance = %1d', tracker_info.viewdist * 10);
    
    
    [v,vs] = Eyelink('GetTrackerVersion');
    disp('***************************************************************')
    fprintf('\tReading Values from %sEyetracker\r', vs)
    disp('***************************************************************')
    [result, reply] = Eyelink('ReadFromTracker', 'screen_pixel_coords');
    fprintf(['Screen pixel coordinates are:\t\t' reply '\r'])
    [result, reply] = Eyelink('ReadFromTracker', 'screen_phys_coords');
    fprintf(['Screen physical coordinates are:\t' reply ' (in mm)\r'])
    [result, reply] = Eyelink('ReadFromTracker', 'screen_distance');
    fprintf(['Screen distance is:\t\t\t' reply '\r'])
    [result, reply] = Eyelink('ReadFromTracker', 'analog_dac_range');
    fprintf(['Analog output range is constraiend to:\t' reply ' (volts)\r'])
    [result, srate] = Eyelink('ReadFromTracker', 'sample_rate');
    fprintf(['Sampling rate is:\t\t\t' srate 'Hz\r'])
    pause(.05)
    [result,reply]=Eyelink('ReadFromTracker','elcl_select_configuration');
    
    tracker_info.srate = str2double(srate);
    tracker_info.trackerversion = vs;
    tracker_info.trackermode    = reply;
    
    switch tracker_info.trackermode
        case {'RTABLER'}
            fprintf('\rSetting up tracker for remote mode\r')
            % remote mode possible add HTARGET ( head target)
            Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
            % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
        otherwise
            tracker_info.callback = [];
            Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT');
            % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,PUPIL,STATUS,INPUT');
    end
    
    
    % custom calibration points
    if tracker_info.custom_calibration
        width  = tracker_info.winRect(3);
        height = tracker_info.winRect(4);
        disp('Setting up custom calibration')
        %         disp('This is not properly implemented yet on 64-bit Eyelink. Works for 32-bit')
        Eyelink('command', 'generate_default_targets = NO');
        
        scale = tracker_info.custom_calibrationScale;
        
        cx = (width/2);
        cy = (height/2);
        Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
            cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
        
        fprintf('calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d\r',...
            cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
        
        Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
            cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
        
        %TODO: what? that's not how it should be done, why not send the
        %calibration scale??
    else
        disp('Using default calibration points')
        Eyelink('command', 'calibration_type = HV9');
        % you must send this command with value NO for custom calibration
        % you must also reset it to YES for subsequent experiments
        Eyelink('command', 'generate_default_targets = YES');
        
    end
    
    
    
    % query host to see if automatic calibration sequencing is enabled.
    % ReadFromTracker needs to have 2 outputs.
    % variables querable are listed in the .ini files in the host
    % directories. Note that not all variables are querable.
    [result, reply] = Eyelink('ReadFromTracker','enable_automatic_calibration');
    
    if reply
        fprintf('Automatic sequencing ON\r');
    else
        fprintf('Automatic sequencing OFF\r');
    end
    
    Eyelink('command',  'inputword_is_window = ON');
    
    
    pause(.05)
    
    [result, tracker_info.EYE_USED] = Eyelink('ReadFromTracker', 'active_eye');
    
    
    
    if strcmp(tracker_info.EYE_USED, 'RIGHT')
        tracker_info.eyeIdx = 2;
    else
        tracker_info.eyeIdx = 1;
    end
    
    Eyelink('message', 'SETUP');
    
    Eyelink('StartRecording');
end



