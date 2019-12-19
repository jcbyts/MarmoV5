classdef protocol < matlab.mixin.Copyable % copyable handle class
  % Matlab class for running an experimental protocl
  %
  % This is the base class for protocols. Set new protocols to inherit
  % this class and you won't have to copy over all the parameters each time.
  %
  
  properties (Access = public)   
       Iti double = 1        % default Iti duration
       startTime double = 0  % trial start time
  end
      
  properties (Access = {?protocols.protocol}) % grant access to all protocol objects
    winPtr % ptb window
    state double = 0      % state counter
    error double = 0      % error state in trial
    %************
    S       % copy of Settings struct (loaded per trial start)
    P       % copy of Params struct (loaded per trial)
    %********* stimulus structs for use
  end
  
  methods (Access = public)
    function o = protocol(winPtr)
        o.winPtr = winPtr;
    end
    
    function state = get_state(o)
        state = o.state;
    end

    function generate_trialsList(~,~,~)
           % nothing for the default. overload this function if you want to
           % generate a trial list
    end
    
    function PR = end_plots(o,~,~)   %update D struct if passing back info     
       % PR = end_plots(o, P, A)
       % Outputs PR struct that will be stored in D
       
       % default should be to save everything
       warning('off'); % suppress warnings about struct2obj function
       PR = struct(o); % conver the object to a struct
       warning('on');
        
    end
    
    % **************** Required methods *************************
    
    initFunc(o,S,P) % initialization caleld 
   
    closeFunc(o) % close function

    next_trial(o,S,P)
       
    prep_run_trial(o)
    
    keepgoing = continue_run_trial(o,screenTime)
   
    drop = state_and_screen_update(o,currentTime,x,y) 
     
    Iti = end_run_trial(o)
    
    plot_trace(o,handles)
    
    
    
  end % methods
    
end % classdef
