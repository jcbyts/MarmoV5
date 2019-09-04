function trialsList = Flag_TrialsList( S, P )
%trialsList = Flag_TrialsList(S,P)
%    S - struct of psychtoolbox settings parameters
%    P - struct of protocol parameters
%  Returns trialsList - list of parameters to substitute over trials

        %******** HERE FOR REFERENCE, JUST LIST THE FIELDS OF LIST
        %   Field 1, 2:   xpos and ypos of target
        %   Field 3:      orientation of target stimulus
        %   Field 4:      size of juice reward (based on condition)
        %   Field 5:      delay from cue onset before saccade allowed
        %   Field 6:      fixation trial or not
        %   Field 7:      post-saccade orientation (NaN if blank)
        
        % Eccentricity sampling, currently only using the radius specified above
        rad = norm([P.xDeg P.yDeg],2);
        % Generate trials list ... note, you may wish to generate the list
        %*****      after changing some P type parameters
        Orinum = P.orinum + P.orinum2;
        trialsList = [];
        if ( (P.fixslots < 1) && (P.fixslots >= 0) )
           FixSlots = ceil( P.fixslots * Orinum / (1 - P.fixslots));
        else
           FixSlots = 0;
        end
        
        for zzk = 1:(Orinum + FixSlots) 
            %***********
            if (zzk <= P.orinum)
                tat = (zzk-1);
                if (P.rangeori == 90) % full circle
                  oro = tat * 180 / P.orinum;   
                else
                  oro = tat * (2*P.rangeori) / (P.orinum-1);
                  oro = oro - P.rangeori + P.prefori;
                end
            else
               if (zzk <= Orinum) 
                  tat = zzk - P.orinum;  % steps 1:P.orinum2 
                  ra = (2*P.rangeori2);
                  step = ra/P.orinum2;
                  oro = P.prefori2 - P.rangeori2 + (tat*step) - (step/2);        
               else
                  oro = 0;  % will not be used 
               end
            end 
            %*******
            for ak = 1:(3*Orinum)  % thirds, 1/3 same, 1/3 change, 1/3 blank
                   %************
                   ora = oro;  % same targ ori post-saccade (default)
                   if (ak > Orinum)
                       if (ak <= (2*Orinum))       
                         amo = mod((ak-1),Orinum) + 1;
                         if (amo <= P.orinum)
                                % ora = ((ak-(2*P.orinum))-1) * 180 / P.orinum;
                                tat = ((ak-Orinum)-1);
                                if (P.rangeori == 90) % full circle
                                  ora = tat * 180 / P.orinum;   
                                else
                                  ora = tat * (2*P.rangeori) / (P.orinum-1);
                                  ora = ora - P.rangeori + P.prefori;
                                end
                         else
                             %here implement for alternative oris
                             tat = ((ak-Orinum)-P.orinum);  % steps 1:P.orinum2
                             ra = (2*P.rangeori2);
                             step = ra/P.orinum2;
                             ora = P.prefori2 - P.rangeori2 + (tat*step) - (step/2);
                             %*******
                         end
                       else
                         ora = NaN; %indicates show blob, no ori
                       end
                   end
                   %************  
                   k = randi(P.apertures);   %randomize location for now
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
                   trialsList = [trialsList ; [xpos ypos oro P.rewardNumber (zzk >= (Orinum+1)) ora]];
            end
        end
        %************
end

