% wrapper class for Arrington eye tracker
% 8/23/2018 - Jude Mitchell

classdef eyetrack < handle
  %******* basically is just a wrapper for a dummy eyetracker
  % 
  
  properties (SetAccess = private, GetAccess = public)
     
  end % properties

  % dependent properties, calculated on the fly...
  properties (SetAccess = public, GetAccess = public)
    EyeDump@logical;
  end

  methods
    function o = eyetrack_arrington(h,varargin), % h is the handle for the marmoview gui

      % initialise input parser
      args = varargin;
      p = inputParser;
      p.addParamValue('EyeDump',true,@islogical); % default 1, do EyeDump
      p.parse(varargin{:});

      args = p.Results;  
      o.EyeDump = args.EyeDump;
      
      % configure the tracker and initialize...  
    end

    function startfile(o,handles),   
        % no file is saved if using mouse
    end
    
    function endtrial(varargin)
    end

    function closefile(o),        
    end

    function unpause(o),    
    end

    function pause(o),    
    end

    function [x,y] = getgaze(o),
        [x,y] = GetMouse;
        %other specs depend on screen and position
    end
    
    function r = getpupil(o),
        r = 1.0;
    end
    
    function sendcommand(o,varargin)
    end
    
  end % methods

  methods (Access = private)

  end % private emethods

end % classdef
