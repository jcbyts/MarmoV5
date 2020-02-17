function [fixation] = isFixation(fixationRadius, xy_pixel,fixation_point, allowblink)
% This function computes if the current position of interest is in the
% location boundary. *The allowblink should be improved. 
if allowblink==0
    n_points = size(xy_pixel, 1);
    
    diffs = xy_pixel - repmat(fixation_point, n_points, 1);
    distances = sqrt(sum(diffs.^2, 2));
    fixation = distances < fixationRadius;
    
else
    n_points = size(xy_pixel, 1);
    
    diffs = xy_pixel - repmat(fixation_point, n_points, 1);
    distances = sqrt(sum(diffs.^2, 2));
    fixation = distances < fixationRadius;
    
    if ~ all(fixation)
        for i=1:n_points
            
            if xy_pixel(i,1) == -32768 && xy_pixel(i,2) == -32768
                fixation=1;
            end
        end
        if fixation==0
            return;
        end
        
    end
    
end

end