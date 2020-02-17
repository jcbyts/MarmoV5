function [tracker_info,broke_fixation,time_stamp,temp_length,count_queue_drawn,fixation1,fixation2] = tracker_sanity(tracker_info,frame,temp_length, count_queue_drawn, fixation_point, duration, allowblink, task,wPtr,image_texture, stimulus_bbox, stimulus_bbox1, stimulus_bbox2)
    %  Left temp_length just in case we use get_queuedata
    broke_fixation=0;
    blinkmark=3;
    fixation1=0;
    fixation2=0;
    black=[0,0,0];
    

    if task==5
    tstart= GetSecs();   
    while GetSecs() - tstart < duration
   
    % tracker_info = Eyelink.getQueue(tracker_info);
%    temp_gx = tracker_info.samples(tracker_info.eyeIdx+13,temp_length+1:end);
 %   temp_gy = tracker_info.samples(tracker_info.eyeIdx+15,temp_length+1:end);
    [eyex, eyey,~] = Eyelink.getGazePoint(tracker_info);

    [fixation_up,~]=Eyelink.isFixation(tracker_info, [eyex eyey], [fixation_point(1,1) fixation_point(1,2)],allowblink);
    [fixation_down,~]=Eyelink.isFixation(tracker_info, [eyex eyey], [fixation_point(2,1) fixation_point(2,2)],allowblink);
    
    if fixation_up
        fixation1=1;
        break;
    elseif fixation_down
        
        fixation2=1;
        break;
    
       
    end
    
    end
    
    if fixation1==0 && fixation2==0
     broke_fixation=1;
        time_stamp=[];
        temp_length=0;
        count_queue_drawn=0;
        return;
    end
    
    end
    
    tstart = GetSecs();
    reference=temp_length;
    tic;
    while GetSecs() - tstart < duration
        count_queue_drawn = count_queue_drawn + 1;
        tracker_info = Eyelink.getQueue(tracker_info);
       
        temp_length = length(tracker_info.samples(tracker_info.eyeIdx+13,:));
       for i=1:4
        [eyex(count_queue_drawn), eyey(count_queue_drawn) , time_stamp(count_queue_drawn)] = Eyelink.getGazePoint(tracker_info);
       eyex_total(i)=eyex(count_queue_drawn);
       eyey_total(i)=eyey(count_queue_drawn);
       end
        
        if task==5
          
        if fixation1
            if blinkmark==3
            [fixation_up, blinkmark]=Eyelink.isFixation(tracker_info, [eyex_total' eyey_total'] , [fixation_point(1,1) fixation_point(1,2)],allowblink);
            else 
            blinkmark=blinkmark+1;
            end
            if ~fixation_up 
                broke_fixation=1;
                return;
            end
        end
        
        if fixation2
            if blinkmark==3
            [fixation_down,blinkmark]=Eyelink.isFixation(tracker_info, [eyex_total' eyey_total'] , [fixation_point(2,1) fixation_point(2,2)],allowblink);
            else 
            blinkmark=blinkmark+1;
            end
            if ~fixation_down 
                broke_fixation=1;
                return;
            end
            
            
        end
        else
            
         if blinkmark==3
         [fixation, blinkmark]= Eyelink.isFixation(tracker_info, [eyex_total' eyey_total'] , fixation_point,allowblink);

      %  fixation = Eyelink.isFixation(tracker_info, [temp_gx' temp_gy'], fixation_point,allowblink);
         else         
         blinkmark=blinkmark+1;
         end
        if ~fixation 
           
            broke_fixation = 1;
            return;
        end
       
        end
        
        fixation_bound = ptbCenteredRect([fixation_point(1), fixation_point(2)], [tracker_info.fixationRadius tracker_info.fixationRadius]);

        
        if task==1
            
             % Prep for first stimulus frame by clearing the drawStimulusFrame.
    Screen('FrameOval', wPtr, black, stimulus_bbox);
    EyeTracker.drawFixationSymbol(tracker_info,fixation_point(1), fixation_point(2), wPtr);
    %% delete later. 
    fixation_bound = ptbCenteredRect([fixation_point(1), fixation_point(2)], [tracker_info.fixationRadius tracker_info.fixationRadius]);
    Screen('FrameOval', wPtr, black, fixation_bound);

    [gx, gy] = Eyelink.getGazePoint(tracker_info);
    Eyelink.drawFixationSymbol(tracker_info,gx,gy, wPtr);
    
    %%
            
            
        elseif task==2
        
        if (frame==1)
            Screen('DrawTexture', wPtr, image_texture(1,frame), [], stimulus_bbox); %Fill the buffer with the first texture
            
        else
            Screen('DrawTexture', wPtr, image_texture(fixation2 + 1,frame-1), [], stimulus_bbox); %Fill the buffer with the first texture
        end
        EyeTracker.drawFixationSymbol(tracker_info,fixation_point(1), fixation_point(2), wPtr);
        
        %% delete later
        Eyelink.drawFixationSymbol(tracker_info,eyex(count_queue_drawn), eyey(count_queue_drawn), wPtr);
        Screen('FrameOval', wPtr, black, fixation_bound);
        %%
        
        elseif task==3
            
        if (frame==1)
            Screen('DrawTexture', wPtr, image_texture(1,frame), [], stimulus_bbox); %Fill the buffer with the first texture
            
        else
            Screen('DrawTexture', wPtr, image_texture(fixation2+1,frame-1), [], stimulus_bbox); %Fill the buffer with the first texture
        end
        EyeTracker.drawFixationSymbol(tracker_info,fixation_point(1), fixation_point(2), wPtr);
        
        Screen('FrameOval', wPtr, black, stimulus_bbox1);
        Screen('FrameOval', wPtr, black, stimulus_bbox2);
        
        %% delete later
        Eyelink.drawFixationSymbol(tracker_info,eyex(count_queue_drawn), eyey(count_queue_drawn), wPtr);
        Screen('FrameOval', wPtr, black, fixation_bound);
        %%
        
        elseif task==4 
          if (frame==1)
            Screen('DrawTexture', wPtr, image_texture(1,frame), [], stimulus_bbox); %Fill the buffer with the first texture
          else
            Screen('DrawTexture', wPtr, image_texture(fixation2+1,frame-1), [], stimulus_bbox); %Fill the buffer with the first texture
            
          end
        EyeTracker.drawFixationSymbol(tracker_info,fixation_point(1), fixation_point(2), wPtr);
        
        Screen('DrawTexture', wPtr, image_texture(1,frame), [], stimulus_bbox1); %Fill the buffer with the first texture
        Screen('DrawTexture', wPtr, image_texture(2,frame), [], stimulus_bbox2); %Fill the buffer with the second texture
        
        
        %% delete later
        
        Eyelink.drawFixationSymbol(tracker_info,eyex(count_queue_drawn), eyey(count_queue_drawn), wPtr);
        Screen('FrameOval', wPtr, black, fixation_bound);
        %%
        
        
        elseif task==5
         if (frame==1)
            Screen('DrawTexture', wPtr, image_texture(1,frame), [], stimulus_bbox); %Fill the buffer with the first texture
        else
            Screen('DrawTexture', wPtr, image_texture(fixation2+1,frame-1), [], stimulus_bbox); %Fill the buffer with the first texture
            
        end
        
        EyeTracker.drawFixationSymbol(tracker_info,fixation_point(1,1), fixation_point(1,2), wPtr);
        EyeTracker.drawFixationSymbol(tracker_info,fixation_point(2,1), fixation_point(2,2), wPtr);
        %% delete later
        Eyelink.drawFixationSymbol(tracker_info,eyex(count_queue_drawn),eyey(count_queue_drawn), wPtr);

        fixation_bound1=ptbCenteredRect([fixation_point(1,1), fixation_point(1,2)], [tracker_info.fixationRadius tracker_info.fixationRadius]);
        Screen('FrameOval', wPtr, black, fixation_bound1);
        
        fixation_bound2=ptbCenteredRect([fixation_point(2,1), fixation_point(2,2)], [tracker_info.fixationRadius tracker_info.fixationRadius]);
        Screen('FrameOval', wPtr, black, fixation_bound2);
        %%    
            
        end
        
        Screen('Flip', wPtr);
        
      
        
    end
    toc
    %ask!
   % temp_gx = tracker_info.samples(tracker_info.eyeIdx+13,temp_length+1:end);
   %temp_gy = tracker_info.samples(tracker_info.eyeIdx+15,temp_length+1:end);
    
  
 if all(tracker_info.samples(tracker_info.eyeIdx+13,reference+1:temp_length)==-32768) && all(tracker_info.samples(tracker_info.eyeIdx+15,reference+1:temp_length)==-32768)
           broke_fixation = 1;
           
            return;
 end
   
    
    































end

