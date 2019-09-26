% wrapper class for Arrington eye tracker
% 8/23/2018 - Jude Mitchell

classdef eyetrack_arrington < handle
    %******* basically is just a wrapper for a bunch of VPX calls
    % the VPX toolbox enables the eye tracker to link into Matlab
    % and to store raw eye data into a .vpx file for off-line analysis
    
    
    properties (SetAccess = public, GetAccess = public)
        EyeDump logical
    end
    
    methods
        function o = eyetrack_arrington(~,varargin) % h is the handle for the marmoview gui
            
            % initialise input parser
            %       args = varargin;
            p = inputParser;
            p.addParameter('EyeDump',true,@islogical); % default 1, do EyeDump
            p.parse(varargin{:});
            
            args = p.Results;
            o.EyeDump = args.EyeDump;
            
            % configure the tracker and initialize...
            vpx_Initialize; % load the ViewPoint libray
            
            if  o.EyeDump
                vpx_SendCommandString('datafile_AsynchStringData Yes');
                vpx_SendCommandString('dataFile_UnPauseUponClose True');
            end
        end
        
        function startfile(o,handles)
            if o.EyeDump
                eyeFile = sprintf('%s_%s_%s_%s.vpx', ...
                    handles.outputPrefix, ...
                    handles.outputSubject, ...
                    handles.outputDate, ...
                    handles.outputSuffix);
                
                fname = fullfile(handles.outputPath,eyeFile);
                vpx_SendCommandString(sprintf('dataFile_NewName "%s"',fname));
                vpx_SendCommandString('dataFile_Pause Yes'); % pause
            end
        end
        
        function closefile(o)
            if o.EyeDump
                vpx_SendCommandString('dataFile_Close');
            end
        end
        
        function unpause(o)
            if o.EyeDump
                vpx_SendCommandString('dataFile_Pause No');
            end
        end
        
        function pause(o)
            if o.EyeDump
                vpx_SendCommandString('dataFile_Pause Yes');
            end
        end
        
        function [x,y] = getgaze(~)
            [x,y] = vpx_GetGazePoint;
            y = 1 - y; % NEED TO INVERT SO ++ IS UP
        end
        
        function r = getpupil(~)
            r = vpx_GetPupilSize;
        end
        
        function sendcommand(~,tstring, ~)
            vpx_SendCommandString(tstring);
        end
        
        function endtrial(~)
            % for compatibility with other eyetrackers
        end
        
    end % methods
    
    methods (Access = private)
        
    end % private emethods
    
end % classdef
