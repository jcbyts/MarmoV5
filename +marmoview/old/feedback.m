% abstract class for providing feedback

% 19-05-2016 - Shaun L. Cloherty <s.cloherty@ieee.org>

classdef (Abstract) feedback < handle
  % Abstract class for providing feedback (e.g., sound, reward etc.).
  %
  % To see the public properties of this class, type
  %
  %   properties(marmoview.feedback)
  %
  % To see a list of methods, type
  %
  %   methods(marmoview.feedback)
  %
  % The class constructor can be called with a range of arguments:
  
  properties (Access = private)
    h; %@handle; % handle for the marmoview gui figure
  end % properties
  
  methods (Access = public)
    function o = feedback(h,varargin),
      o.h = h;
    end
    
    % called to deliver the feedback...
    deliver(o,varargin); % abstract method?
    
    % called at the end of each trial to provide info to the gui...?
    report(o,varargin); % abstract method?
  end % methods  
end % classdef
