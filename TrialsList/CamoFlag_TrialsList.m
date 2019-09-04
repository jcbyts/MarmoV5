function trialsList = CamoFlag_TrialsList( S, P )
%trialsList = DelayCue7_TrialsList(S,P)
%    S - struct of psychtoolbox settings parameters
%    P - struct of protocol parameters
%  Returns trialsList - list of parameters to substitute over trials

        %******** HERE FOR REFERENCE, JUST LIST THE FIELDS OF LIST
        %   Field 1, 2:   xpos and ypos of target
        %   Field 3:      orientation of target stimulus
        %   Field 4:      size of juice reward (based on condition)
        %   Field 5:      delay from cue onset before saccade allowed
        %   Field 6:      fixation trial or not
        
        % Eccentricity sampling, currently only using the radius specified above
        rad = norm([P.xDeg P.yDeg],2);
        % Generate trials list ... note, you may wish to generate the list
        %*****      after changing some P type parameters
        trialsList = [];
        if ( (P.fixslots < 1) && (P.fixslots >= 0) )
           FixSlots = ceil( P.fixslots * P.orinum / (1 - P.fixslots));
        else
           FixSlots = 0;
        end
        
        for zzk = 1:(P.orinum + FixSlots) 
        %for zzk = 1:P.orinum  % (P.orinum+1)
               oro = (zzk-1) * 180 / P.orinum;
               for k = 1:P.apertures
       
                   %************  
                   ango = 2*pi*(k-1)/P.apertures;  % default, all around ring
                   %****
                   if isfield(S,'subject')
                       if (strcmp(S.subject,'Ellie'))   % case sensitive
                 
                         ango = -pi/4 + (pi/2)*(k-1)/P.apertures;
                       end
                   end
                   %********

                    xpos = cos(ango) * rad;
                    ypos = sin(ango) * rad;     
                    % Trials list is comprised of varied params per trial
                    %trialsList = [trialsList ; [xpos ypos oro P.rewardNumber P.delay (zzk == (P.orinum+1))]];
                    trialsList = [trialsList ; [xpos ypos oro P.rewardNumber P.delay (zzk >= (P.orinum+1))]];
               end
        end
        %************


end

