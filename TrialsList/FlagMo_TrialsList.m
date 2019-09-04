function trialsList = FlagMo_TrialsList( S, P )
%trialsList = FlagMo_TrialsList(S,P)
%    S - struct of psychtoolbox settings parameters
%    P - struct of protocol parameters
%  Returns trialsList - list of parameters to substitute over trials

        %******** HERE FOR REFERENCE, JUST LIST THE FIELDS OF LIST
        %   Field 1, 2:   xpos and ypos of target
        %   Field 3:      orientation of target stimulus
        %   Field 4:      size of juice reward (based on condition)
        %   Field 5:      fixation trial or not
        %   Field 6:      post-saccade orientation (NaN if blank)
        
        % Eccentricity sampling, currently only using the radius specified above
        rad = norm([P.xDeg P.yDeg],2);
        % Generate trials list ... note, you may wish to generate the list
        %*****      after changing some P type parameters
        Orinum = P.orinum;
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
                oro = tat * 360 / P.orinum; 
            else
                oro = 0;  % will not be used 
            end 
            %*******
            for ak = 1:(3*Orinum)  % thirds, 1/3 same, 1/3 change, 1/3 blank
                   %************
                   ora = oro;  % same targ ori post-saccade (default)
                   if (ak > Orinum)
                       if (ak <= (2*Orinum))       
                         tat = ((ak-Orinum)-1);
                         ora = tat * 360 / P.orinum;
                       else
                         ora = NaN; %indicates show blob, no ori
                       end
                   end
                   for k = 1:P.targnum     % sample from RF and other locations
                       %************  
                       xps = P.RF_X;
                       yps = P.RF_Y;
                       %*******
                       ango = 2*pi*(k-1)/P.targnum;  % shift the position
                       xpos = (cos(ango) * xps) + (sin(ango) * yps);
                       ypos = (-sin(ango) * xps) + (cos(ango) * yps);
                       % Trials list is comprised of varied params per trial
                       trialsList = [trialsList ; [xpos ypos oro P.rewardNumber (zzk >= (Orinum+1)) ora]];
                   end
            end
        end
        %************
end

