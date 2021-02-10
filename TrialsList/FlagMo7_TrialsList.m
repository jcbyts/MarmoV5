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
        for zzk = 1:Orinum 
            %***********
            if (zzk <= P.orinum)
                tat = (zzk-1);
                if (P.motionStimulus == 1)
                   oro = tat * 360 / P.orinum;
                else
                   oro = tat * 180 / P.orinum;
                end
            else
                oro = 0;  % will not be used 
            end 
            %*******
            for ak = 1:(5*Orinum)  % fifths, 2/5 same, 1/5 change, 1/5 blank, 1/5 fixation stim
                                   % (jude changed to fifths from fourths)
                   %************
                   ora = oro;  % same targ ori post-saccade (default)
                   fixslot = 0;
                   if (ak > (2*Orinum))
                       if (ak <= (3*Orinum))       
                         tat = ((ak-(2*Orinum))-1); % not used exactly, +90 or -90 later
                         if (tat < (floor(Orinum/2)) )
                             ora = oro - 90;
                             if (ora < 0)
                                 ora = ora + 360;
                             end
                         else
                             ora = oro + 90;
                             if (ora >= 360)
                                 ora = ora - 360;
                             end
                         end
                         % ora = tat * 360 / P.orinum;
                       else
                         if (ak <= (4*Orinum))     
                            ora = NaN; %indicates show blob, no ori
                         else
                            ora = oro;
                            fixslot = 1;  % show stim at fix, train decoder
                         end
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
                       trialsList = [trialsList ; [xpos ypos oro P.rewardNumber fixslot ora]];
                   end
            end
        end
        %************
end

