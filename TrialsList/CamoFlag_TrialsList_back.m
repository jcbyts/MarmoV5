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
        for zzk = 1:P.orinum  % (P.orinum+1)
               oro = (zzk-1) * 180 / P.orinum;
               for k = 1:P.apertures
                   % ango = ((k-1) * 2 * pi)/P.apertures;
                   ango = -pi/4 + (pi/2)*(k-1)/P.apertures;
                   
%                     a = -pi/4;
%                     b = pi/4;
%                     ango = (b-a).*rand(1) + a;

                    xpos = cos(ango) * rad;
                    ypos = sin(ango) * rad;     
                    % Trials list is comprised of varied params per trial
                    %trialsList = [trialsList ; [xpos ypos oro P.rewardNumber P.delay (zzk == (P.orinum+1))]];
                    trialsList = [trialsList ; [xpos ypos oro P.rewardNumber P.delay 0]];
               end
        end
        %************


end

