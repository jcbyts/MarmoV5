% wrapper class for Arrington eye tracker
% 8/23/2018 - Jude Mitchell

classdef eyetrack < handle
  %******* basically is just a wrapper for a dummy eyetracker
  % 
  
  properties (SetAccess = private, GetAccess = public)
     
  end % properties

  % dependent properties, calculated on the fly...
  properties (SetAccess = public, GetAccess = public)
    EyeDump logical
  end
    
    methods
        function o = eyetrack_arrington(~,varargin) % h is the handle for the marmoview gui
            
            % initialise input parser
            p = inputParser;
            p.addParameter('EyeDump',true,@islogical); % default 1, do EyeDump
            p.parse(varargin{:});
            
            args = p.Results;
            o.EyeDump = args.EyeDump;
            
            % configure the tracker and initialize...
        end
        
        function startfile(~,~)
            % no file is saved if using mouse
        end
        
        function closefile(~)
        end
        
        function unpause(~)
        end
        
        function pause(~)
        end
        
        function endtrial(~)
        end
        
        function [x,y] = getgaze(~)
            [x,y] = GetMouse;
            %other specs depend on screen and position
        end
        
        function r = getpupil(~)
            r = 1.0;
        end
        
        function sendcommand(~,~,~)
        end
        
    end % methods
    
    methods (Access = private)
        
    end % private emethods
    
end % classdef
