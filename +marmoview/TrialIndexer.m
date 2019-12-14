% class to keep track of trial indexes over a trial list
% by Jude, 9/2/2018   -- handles trial indexing over blocks

classdef TrialIndexer < handle
  
  properties (SetAccess = private, GetAccess = public)
    trialN;
    trialPerm;
    trialComp;  %track trials completed
    trialInd;  %will step to 1 if no error 
  end % properties
   
  % dependent properties, calculated on the fly...
  properties (SetAccess = public, GetAccess = public)
    corstates double             % correct states to continue trial  
    repstates double             % error states for which to repeat trial
    RepeatUntilCorrect double    % if one, repeat till all trials correct
  end
  
  methods
      
    function o = TrialIndexer(TrialsList,P,corstates,repstates) % h is the handle for the marmoview gui
      
      if (isempty(TrialsList))
          o.trialN = 1;   %it will always return trial 1 if so
      else
          o.trialN = size(TrialsList,1);
      end
      o.resetTrialBuffer();
      if (isfield(P,'RepeatUntilCorrect'))
          o.RepeatUntilCorrect = P.RepeatUntilCorrect;
      end
      if isempty(corstates)
          o.corstates = 0;  % error 0 means correct, default
      else
          o.corstates = corstates;
      end
      if isempty(repstates)
          o.repstates = 1;  % error 1 is an abort, repeat it
      else
          o.repstates = repstates;
      end
    end

    function trialInd = getNextTrial(o, error)
         if o.RepeatUntilCorrect         
              if ismember(error,o.corstates) % correct trials marked complete
                 o.trialComp(o.trialInd) = 1;
              end
              if (sum(o.trialComp) == o.trialN)  % all correct, then reset
                   o.resetTrialBuffer();
              else     % find next index not complete
                  findit = 1;
                  k = o.trialInd;
                  while findit
                      k = k + 1;
                      if (k > o.trialN)
                          k = 1;
                      end
                      if (o.trialComp(k) == 0)
                          break;
                      end
                  end
                  o.trialInd = k;
              end
         else 
              %******* only repeat if an abort or fix break
              if  ~ismember(error,o.repstates)  % not abort or break fix
                 o.trialInd = o.trialInd+1;  % always step forward
                 if o.trialInd >= o.trialN
                   o.resetTrialBuffer();
                 end   
              end
         end
         %*******************
         trialInd = o.trialPerm(o.trialInd);  
    end
    
    function resetTrialBuffer(o)
         o.trialPerm = randperm(o.trialN);
         o.trialComp = zeros(1,o.trialN);  %track trials completed
         o.trialInd = 1;  %will step to 1 if no error
    end
    
  end  % methods
  
end % classdef
