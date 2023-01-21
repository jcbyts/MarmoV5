% wrapper class for Eyelink eye tracker
% 8/23/2018 - Jude Mitchell .... very basic and similar to VPX approach

classdef eyetrack_eyelink < handle
  %******* basically is just a wrapper for a bunch of EDF calls
  % the Matlab toolbox originates from Jake and PLDAPS calls to EyeLink
  % and to store raw eye data into a .edf file for off-line analysis
  

  properties (SetAccess = public, GetAccess = public)
    EyeDump logical;
    eyeIdx = 1;   % LEFT EYE, Default
    screen = 0;
    tracker_info = [];
    eyeFile = [];
    eyePath = [];
  end
  
  methods
    function o = eyetrack_eyelink(h,winPtr,eyeFile,eyePath,varargin), % h is the handle for the marmoview gui

      % initialise input parser
      args = varargin;
      p = inputParser;
      p.addParameter('EyeDump',true,@islogical); % default 1, do EyeDump
      p.addParameter('screen',0,@isfloat); % default 1, do EyeDump
      p.parse(varargin{:});

      args = p.Results;  
      o.EyeDump = args.EyeDump;
      o.screen = args.screen;
      
      %******** save desired output file path to move edf file at end
      o.eyeFile = eyeFile;
      o.eyePath = eyePath;
      %***********************
      
      if o.screen    
           o.tracker_info = Eyelink.Initialize_params(o.screen, winPtr, 'eyelink_use',1,'saveEDF',o.EyeDump);
           o.tracker_info = Eyelink.setup(o.tracker_info);
           if (strcmp(o.tracker_info.EYE_USED,'RIGHT'))
               o.eyeIdx = 2;
           else
               o.eyeIdx = 1;
           end
      end
      
    end

    function startfile(o,handles),   
        if o.EyeDump
           %note empty function here, startfile happens on init for Eyelink
           % so see the setup function above
        end
    end
    
    function closefile(o),       
        if o.EyeDump 
           Eyelink('CloseFile'); 
           if ~isempty(o.eyeFile) && ~isempty(o.eyePath)
               file = o.tracker_info.edfFile;
               result = Eyelink('Receivefile',file,pwd,1); 
               if (result == -1)
                   warning('pds:EyelinkGetFiles', ['receiving ' file '.edf failed!'])   
               else
                   file_edf = [file,'.edf'];
                   disp(['Files received: ' file_edf]);
                   disp('   ');
                   filedest = [fullfile(o.eyePath,o.eyeFile),'.edf'];
                   [result,mess,messid] = movefile(file_edf,filedest);
                   if (result == 0)
                       disp(sprintf('Error in moving .edf file %s to %s',file,filedest));
                       disp(mess);
                       messid
                   else
                       disp(sprintf('Success: moved %s to %s',file,filedest));
                       delete(file);
                   end
               end
           end
        end
        Eyelink.finish(o.tracker_info);
    end

    function unpause(o),    
        if o.EyeDump
           Eyelink('StartRecording');   
           % vpx_SendCommandString('dataFile_Pause No');
        end
    end

    function pause(o),    
        if o.EyeDump
          Eyelink('StopRecording');  
          % vpx_SendCommandString('dataFile_Pause Yes');
        end
    end

    function [x,y] = getgaze(o),
           eye_data = Eyelink('NewestFloatSample');
           if isfield(eye_data,'gx')
               x = -eye_data.px(o.eyeIdx)/32768;  
               y = eye_data.py(o.eyeIdx)/32768; 
               y = 1 - y;  % why bother retaining this from VPX?
           else
               disp(num2str(eye_data))
               x = 0;
               y = 0;
           end
    end
    
    function r = getpupil(o),
        r = 0;  % don't need it online, will see if EDF file has it
    end
    
    function sendcommand(o,tstring, varargin),
        Eyelink('message', tstring);
    end
    
    function endtrial(~)
    end
    
  end % methods

  methods (Access = private)

  end % private emethods

end % classdef
