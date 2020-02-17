function eraseTarget(tracker_info, x,y)
% erase calibration target
%
% USAGE: eyelink.cal.eraseTarget(p, x,y)
%
% [p]  structure
% [x],[y] target location


tempcolor = tracker_info.calibration_color;
Screen('Drawdots',tracker_info.wPtr,[x; y], tracker_info.calibrationtargetsize, tempcolor,[],2)

Screen( 'Flip',  tracker_info.wPtr);
end