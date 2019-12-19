% abstract class for providing feedback

% 19-05-2016 - Shaun L. Cloherty <s.cloherty@ieee.org>

classdef (Abstract) feedback < handle & matlab.mixin.Copyable
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
  
  properties (GetAccess = public, SetAccess = protected)
  log=[]
  end
  
  properties (Access = protected)
%     h@handle; % handle for the marmoview gui figure
  end % properties
  
  methods (Access = public)
    function o = feedback(varargin)
%       o.h = h;
    end
    
    % called to deliver the feedback...
    deliver(o,varargin); % abstract method?
    
    % called at the end of each trial to provide info to the gui...?
    report(o,varargin); % abstract method?
    
    function clearlog(o)
        o.log = [];
    end
  end % methods  
end % classdef
