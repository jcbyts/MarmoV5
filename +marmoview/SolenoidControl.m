% wrapper class for New Era syringe pumps
% that has been adapted by Jude and Keith for a solenoid juice delivery
% 10/5/2018

classdef SolenoidControl < handle % marmoview.liquid
    % StimulusControl - frontend to usb serial relay that controls the stimulus presentation timing for experiment
    % see https://numato.com/docs/1-channel-usb-powered-relay-module/
    % for details on protocol
    %
    % NOTE: need to send the EndLine character BEFORE and after sending
    % commands or they get lost
  
  properties (SetAccess = private, GetAccess = public)
       ComPortName = 'COM4'
       JuicerPort = '0'
       FixationPort = '1'
       FixationLostPort = '2'
       IncorrectPort = '3'
  end % properties

   properties (Dependent, SetAccess = public, GetAccess = public)
     volume@double = 0;   % dispensing volume (mL)
   end

   %% Public
   properties
       % in s
       JuicerDuration  = .5
       % in s
       FixationDuration  = .3
       % in s
       FixationLostDuration  = .3
       % in s
       IncorrectDuration  = .3
   end
   
   %% Private serial line commands
   properties(Constant, Access=private)
       EndLine = char(hex2dec('0d'))
       TurnOnCmd = 'relay on '
       TurnOffCmd = 'relay off '
       StatusCmd = 'relay read '
   end
   
   properties(Access=private)     
       SerialPort    
   end
   
  methods % set/get dependent properties
   
     % Constructor
     function o = SolenoidControl(comport)
           o.ComPortName=comport;
           o.SerialPort = serial(o.ComPortName,'BaudRate',9600);
           fopen(o.SerialPort);
     end
       
     % Destructor
     function delete(o)
          fclose(o.SerialPort);
          delete(o.SerialPort);
     end

     function o = set.volume(o,value),
        % note: not volume for solenoid, but duration of pulse
        o.JuicerDuration  = value;  % ul in the GUI, is millisecs here
     end

     function value = get.volume(o),
       value = o.JuicerDuration; %
     end
    
    function err = deliver(obj,varargin),
      err = 0;
      tmr = timer('StartFcn',@(ev,ob)fprintf(obj.SerialPort,  [obj.EndLine obj.TurnOnCmd obj.JuicerPort obj.EndLine],  'sync'), ...
               'TimerFcn',@(ev,ob)pause(obj.JuicerDuration), ...
               'StopFcn', @(ev,ob)fprintf(obj.SerialPort,  [obj.EndLine obj.TurnOffCmd obj.JuicerPort obj.EndLine],  'sync'));
         
      start(tmr)
    end

    function r = report(o),
      r.totalVolume = 0; 
    end
    
  end % methods

end % classdef
