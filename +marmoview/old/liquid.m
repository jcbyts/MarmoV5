% abstract class for providing feedback in the form of a liquid reward

% 23-05-2016 - Shaun L. Cloherty <s.cloherty@ieee.org>

classdef (Abstract) liquid < marmoview.feedback
  % Abstract class for providing liquid reward.
  %
  % To see the public properties of this class, type
  %
  %   properties(marmoview.liquid)
  %
  % To see a list of methods, type
  %
  %   methods(marmoview.liquid)
  %
  % The class constructor can be called with a range of arguments:
  
  properties (Abstract)
    volume double % must be declared by the concrete subclass
  end
  
  methods
    function o = liquid(h,varargin)
      o = o@marmoview.feedback(h,varargin{:});
    end
  end
end % classdef