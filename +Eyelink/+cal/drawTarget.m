function drawTarget(tracker_info, x, y)
% function drawTarget(p, x, y)
% draw simple calibration target

tempcolor = tracker_info.calibrationtargetcolor;
Screen('Drawdots',tracker_info.wPtr,[x; y], tracker_info.calibrationtargetsize, tempcolor,[],2)

Screen( 'Flip',  tracker_info.wPtr);
end