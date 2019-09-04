function trialsList = DelayCue7_TrialsList( S, P)
%trialsList = DelayCue7_TrialsList(S,P,subject)
%    S - struct of psychtoolbox settings parameters
%    P - struct of protocol parameters
%  Returns trialsList - list of parameters to substitute over trials

        %******** HERE FOR REFERENCE, JUST LIST THE FIELDS OF LIST
            %   Field 1, 2:   xpos and ypos of target
            %   Field 3:      length of central line cue
            %   Field 4:      size of juice reward (based on condition)
            %   Field 5:      delay from cue onset before saccade allowed
            %   Field 6:      delay number (integer of condition)
            %   Field 7:      cueColor - brightness (or darkness) of cue
            %   Field 8:      cued peak time (cue fades in and out)
            %   Field 9:      cued width (duration of fade in and out)
            %   Field 10:     singleton (on some trials run single stim, no
            %                            distractors ... sample a location)

        %******* Given the S and P structs, build your trial list
        %******* Specifies what parameters you want to vary over Exp Trials
        %*******  and then returns the Trial List
        if (0) % early training with no spatial cues
          sf_sampling =     [0.1 0.1 0.1 0.1 0.1 0.1];   %when set to 0.1, fixation only trial
                                                         % set this to some length
                                                         % > 1.0 (up to 5) for a
                                                         % cue trial when ready
          delay_sampling =  [0.1 0.2 0.3 0.5 0.7 1.0];   % period to hold fixation
          cue_peak =        [1.0 1.0 1.0 1.0 1.0 1.0];   % not used here anyway
          cue_width =       [0.5 0.5 0.5 0.5 0.5 0.5];   % also not used here
          delay_juice =     [  2   2   2   3   4   5];
          singleton =       [  0   0   0   0   0   0]; 
        else
            
           % default settings: 
           % sf_sampling =     [5      5      4.5    4      3.5    3.0     0.1    0.1    2.0];   
           % sf_sampling =     [5      3      2.5    2      1.5    1.2     0.1    0.1    1.5];   
           sf_sampling =     [4      3      2.5    2      1.5    1.2     0.1    0.1    1.5];   
           delay_sampling =  [0.101  0.102  0.103  0.104  0.105  0.106   0.25   0.30   0.110];
           cue_peak =        [0.10   0.10   0.10   0.10   0.10   0.10    1.0    1.0    0.10]; 
           cue_width =       [0.2    0.2    0.2    0.2    0.2    0.2     0.5    0.5    0.2];   % also not used here
           delay_juice =     [1      1      2      2      3      5       2      2      2];
           singleton =       [0      0      0      0      0      0       0      0      1];
           
           if isfield(S,'subject')
             if (strcmp(S.subject,'Allen'))   % case sensitive
                 % sf_sampling =     [5      4      3    2.5      2    1.5     0.1    0.1    1.5];   
                 sf_sampling =     [5      5      4.5    4      3.5    2.5     0.1    0.1    1.5];   
                 delay_sampling =  [0.101  0.102  0.103  0.104  0.105  0.106   0.25   0.30   0.110];
                 cue_peak =        [0.10   0.10   0.10   0.10   0.10   0.10    1.0    1.0    0.10]; 
                 cue_width =       [0.2    0.2    0.2    0.2    0.2    0.2     0.5    0.5    0.2];   % also not used here
                 delay_juice =     [1      1      2      2      4      6       2      2      2];
                 % delay_juice =     [1      1      2      2      3      5       2      2      2];
                 singleton =       [0      0      0      0      0      0       0      0      1];
             end
           end
           
        end

        % Eccentricity sampling, currently only using the radius specified above
        rad = norm([P.xDeg P.yDeg],2);
        if (P.SamplingDirections == 1) || (P.SamplingDirections == 4)
            klist = 1:P.apertures;
        else
            if (P.SamplingDirections == 2)  % cardinal
                klist = 1:2:P.apertures;
            else
                klist = 2:2:P.apertures;  % diagonals
            end
        end
        % Generate trials list ... note, you may wish to generate the list
        %*****      after changing some P type parameters
        trialsList = [];
        for zzk = 1:size(delay_sampling,2)
               for k = klist   % vary what directions sampled
                    ango = ((k-1) * 2 * pi)/P.apertures;  
                    xpos = cos(ango) * rad;
                    ypos = sin(ango) * rad;     
                    % Trials list is comprised of varied params per trial
                    mmjuice = 0;
                    mnjuice = delay_juice(zzk); 
                    mjuice = mmjuice + mnjuice;
                    if (mjuice > P.rewardNumber)
                        mjuice = P.rewardNumber;
                    end
                    trialsList = [trialsList ; [xpos ypos sf_sampling(zzk) mjuice delay_sampling(zzk) zzk P.cueColor cue_peak(zzk) cue_width(zzk) singleton(zzk)]];
               end
        end
        %************


end

