function clearDisplay(tracker_info)
% eyelink.cal.clearDisplay
% clears the display
Screen('FillRect',  tracker_info.wPtr, tracker_info.calibration_color);	% clear_cal_display()
Screen( 'Flip',  tracker_info.wPtr);
end

