function [gx,gy,time_stamp_ms] = getGazePoint(tracker_info,units)
%GETGAZEPOINT get xy location from eye tracker in pixel co-ordinates if units is pixels 
%else returns gaze co-ordinates and time stamp in ms.
%

if ~tracker_info.eyelink_use
    [gx, gy] = GetMouse(tracker_info.wPtr); 
    time_stamp_ms = 0;
else
    if nargin<2
        units = 'pixels';
    end
    if strcmpi(units,'pixels')
    eye_used = tracker_info.eyeIdx ;
    eye_data = Eyelink('NewestFloatSample');     
    gx = eye_data.gx(eye_used); 
    gy = eye_data.gy(eye_used);
    time_stamp_ms = eye_data.time;
    elseif strcmpi(units,'gaze')
      eye_used = tracker_info.eyeIdx ;
      eye_data = Eyelink('NewestFloatSample');
      gx = eye_data.hx(eye_used);
      gy = eye_data.hy(eye_used);
      time_stamp_ms = eye_data.time;
    else 
        disp('Error: Unknown format to return!!');
    end
end

% if nargout == 1
%     varargout{1} = [gx, gy];
% elseif nargout == 2
%     varargout{1} = [gx, gy];
%     varargout{2} = time_stamp_ms;
% end
end