% wrapper class for New Era syringe pumps

% 25-06-2016 - Shaun L. Cloherty <s.cloherty@ieee.org>

classdef newera_IOport < marmoview.liquid
  % Wrapper class for New Era syringe pumps (see http://syringepump.com/).
  %
  % To see the public properties of this class, type
  %
  %   properties(marmoview.newera)
  %
  % To see a list of methods, type
  %
  %   methods(marmoview.newera)
  %
  % The class constructor can be called with a range of arguments:
  %
  %   port     - serial interface (e.g., COM1)
  %   baud     - baud rate (default: 19200)
  %   address  - pump address (0-99)
  %   diameter - syringe diameter (mm)
  %   volume   - dispensing volume (ml)
  %   rate     - dispensing rate (ml per minute)
  
  properties (SetAccess = private, GetAccess = public)
    dev   % IOPort

    port; % port for serial communications ('COM1','COM2', etc.)
    baud;
    
    address double; % pump address (0-99)
    
    triggerMode
    alarmMode
    lowNoiseMode
    volumeUnits
  end % properties

  % dependent properties, calculated on the fly...
  properties (SetAccess = public, GetAccess = public)
    diameter double; % diameter of the syringe (mm)
    volume double;   % dispensing volume (mL)
    rate double;     % dispensing rate (mL per minute)
  end
  
  properties (SetAccess = private, GetAccess = private)
      commandSeparator
  end

  methods % set/get dependent properties
      % dependent property set methods
      function set.diameter(o,value)
          if ~isempty(o.dev)
              o.setdia(value);
          else
              o.diameter = value;
          end
      end % set.diameter

    function set.volume(o,value)
        
        if ~isempty(o.dev)
            
            % note: value is in ml, however, if diameter > 14.0mm, the pump
            %       is expecting volume in microliters (unless the default units
            %       have been over-riden).
            if o.diameter <= 14.0
                value = value*1e3; % microliters
            end
            o.setvol(value);
            o.volume = value;
        else
            o.volume = value;
        end
        
    end % set.volume

    function set.rate(o,value)
        if ~isempty(o.dev) %#ok<*MCSUP>
            o.setrate(value);
            o.rate = value;
        else
            o.rate = value;
        end
        
    end % set.rate

    % dependent property get methods
    function value = getdiameter(o)
        if ~isempty(o.dev)
            a=char(IOPort('Read',o.dev,1,14));
            value=str2double(a(10:end));
        else
            value = o.diameter;
        end
    end % get.diameter

    function value = getvolume(o)
        if ~isempty(o.dev)
            [~, ~, err] = IOPort('Write', o.dev, 'VOL');
            msg = IOPort('Read', o.dev);
%             [err,~,msg] = o.sndcmd('VOL');
            assert(err == 0);
            
            pat = '(?<value>[\d\.]{5})\s*(?<units>[A-Z]{2})';
            tokens = regexp(msg,pat,'names');
            
            value = str2double(tokens.value);
            
            
            % note: value should be returned in ml, however, if diameter <= 14.0mm,
            %       the pump returns the volume in microliters (unless the default
            %       units have been over-riden).
            switch upper(tokens.units)
                case 'ML' % milliliters
                    % do nothing
                case 'UL' % microliters
                    value = value/1e3; % milliliters
                otherwise
                    warning('MARMOVIEW:NEWERA','Unknown volume units ''%s''.', tokens.units);
            end
        else
            value = o.volume;
        end
    end % get.volume

    function value = getrate(o)
        if ~isempty(o.dev)
            [err,~,msg] = o.sndcmd('RAT');
            assert(err == 0);
            
            pat = '(?<value>[\d\.]{5})\s*(?<units>[A-Z]{2})';
            tokens = regexp(msg,pat,'names');
            
            value = str2double(tokens.value);
            
            switch upper(tokens.units)
                case 'MM' % milliliters per minute
                    % do nothing
                case 'MH' % millimeters per hour
                    value = value/60.0; % milliliters per minute
                case 'UM' % microliters per minute
                    value = value/1e3; % milliliters per minute
                case 'UH' % microliters per hour
                    value = value/(60*1e3); % milliliters per minute
                otherwise
                    warning('MARMOVIEW:NEWERA','Unknown rate units ''%s''.', tokens.units);
            end
            
        else
            value = o.rate;
        end
    end % get.rate
    
  end % set/get methods

  methods
    function o = newera_IOport(h, varargin) % constructor

	  newargs = varargin;
      if nargin > 0 && isstruct(varargin{1})
          structArg = varargin{1};
          if nargin > 1
              newargs = varargin{2:end};
          end
      end
      
      o = o@marmoview.liquid(h,varargin{:}); % call parent constructor
%       o = o@marmoview.liquid(newargs{:}); % call parent constructor

      % parse optional arguments
      args = newargs;
      
      ip = inputParser;
      ip.KeepUnmatched = true;
      ip.StructExpand = true;
      ip.addParameter('port','COM1',@ischar); % default to COM1?
      ip.addParameter('baud',9600,@(x) any(ismember(x,[300, 1200, 2400, 9600, 19200])));

      ip.addParameter('address',0,@(x) isreal);
      
      ip.addParameter('diameter',20.0,@isreal); % mm
      ip.addParameter('volume',0.010,@isreal); % ml
      ip.addParameter('rate',10.0,@isreal); % ml per minute
      ip.addParameter('alarmMode', 0)
      ip.addParameter('lowNoiseMode', 0)
      ip.addParameter('triggerMode', 'T2', @(x) any(strcmp(x, {'F2', 'T2'})))
      ip.addParameter('volumeUnits', 'UL', @(x) any(strcmp(x, {'ML', 'UL'})))

      ip.parse(args{:});

      args = ip.Results;
      if exist('structArg', 'var')
          args = mergeStruct(args, structArg);
      end
      

      o.port        = args.port;
      o.baud        = args.baud;
      o.triggerMode = args.triggerMode;
      o.alarmMode   = args.alarmMode;
      o.lowNoiseMode = args.lowNoiseMode;
      o.volumeUnits  = args.volumeUnits;

      o.address = args.address;
      
      if nargin < 1 % if nothing was passed in, assume base obj
          return
      end

      % now try and connect to the New Era syringe pump...
      o.open();
      
      o.diameter = args.diameter;
      o.volume   = args.volume;
      o.rate     = args.rate;
       
    end % constructor

    function open(o)

        %
        %   data frame: 8N1 (8 data bits, no parity, 1 stop bit)
        %   terminator: CR (0x0D)
        config=sprintf('BaudRate=%d DTR=1 RTS=1 ReceiveTimeout=1', o.baud);
        %% Open port
        [h, errmsg]=IOPort('OpenSerialPort', o.port, config);% Mac:'/dev/cu.usbserial' Linux:'/dev/ttyUSB0'
        WaitSecs(0.1);
        if ~isempty(errmsg)
            error('pds:newEraSyringePump:setup',sprintf('Failed to open serial Port with message %s\n',errmsg)); %#ok<SPERR>
        end
        
        %% Configure pump
        o.dev = h;
        
        % serial com line terminator
        o.commandSeparator = [char(13) repmat(char(10),1,20)]; %#ok<CHARTEN>
        
%         % flush serial command pipeline (no command)
        IOPort('Write', o.dev, [o.commandSeparator],0);
%         % set syringe diameter
        IOPort('Write', o.dev, ['DIA' o.commandSeparator],0);%0.05
%         % set pumping direction to INFuse   (INF==infuse, WDR==withdraw, REV==reverse current dir)
        IOPort('Write', o.dev, ['DIR INF'  o.commandSeparator],0);
%         % enable/disable low-noise mode (logical, attempts to reduce high-freq noise from slow pump rates...unk. effect/utility in typical ephys enviro. --TBC)
        IOPort('Write', o.dev, ['LN ' num2str(o.lowNoiseMode) o.commandSeparator],0); %low noise mode, try
%         % enable/disable audible alarm state (0==off, 1==on/use)
        IOPort('Write', o.dev, ['AL ' num2str(o.alarmMode) o.commandSeparator],0); %low noise mode, try
%         % set TTL trigger mode ('T2'=="Rising edge starts pumping program";  see NE-500 user manual for other options & descriptions)
        IOPort('Write', o.dev, ['TRG ' o.triggerMode  o.commandSeparator],0);
%         
        WaitSecs(0.1);
        
        % use sndcmd instead
        flushin(o)
        o.sndcmd(['VOL ' o.volumeUnits]);
        o.sndcmd(['AL ' o.alarmMode]);
        o.sndcmd(['LN ' o.lowNoiseMode]);
        o.sndcmd('DIR INF') % Infuse;
        
        
        
        
    end % open

    function close(o)
        if ~isempty(o.dev)
            IOPort('close',o.dev)
        end
        o.dev = [];
    end % close

    function delete(o)
%         try
%             o.close(); % fails if o.dev is invalid or is already closed
%         catch
%         end
%         o.dev = [];
    end % delete
    
    function err = deliver(o,amount)
%       fprintf(1,'marmoview.newera.deliver()\n');

      % too slow, this calls the sndcmd() method which involves both a
      % synchronous write operation *and* a synchronous read operation
%       err = run(o);

      % this is inelegant, but fast(er)... it involves only an asynchronous
      % write operation and bypasses the sndcmd() method entirely. However
      % the response from the pump is not read so we need to modify sndcmd()
      % below to flush the input buffer before any subsequent read operation
      err = 0;

      if nargin < 2 % repeat last given Volume
          IOPort('Write', o.dev, ['RUN' o.commandSeparator],0);
      elseif amount>=0.001 && amount<=9999
          %             IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' num2str(amount) p.trial.newEraSyringePump.commandSeparator],0);
          %             IOPort('Write', p.trial.newEraSyringePump.h, ['RUN' p.trial.newEraSyringePump.commandSeparator],0);
          IOPort('Write', o.dev, ['VOL ' sprintf('%*.*f', ceil(log10(amount)), min(3-ceil(log10(amount)),3),amount) o.commandSeparator 'RUN' o.commandSeparator],0);
      end
%       IOport('Write', o.dev,'00 RUN');
      
      o.log = [o.log GetSecs]; % log all reward calls

    end

    function r = report(o)
      r.totalVolume = o.qryvol();
    end
    
    % save out the object as a struct
    function s = saveobj(obj)
%         disp('custom save for reward object')
        pl = properties(obj);
        pl = setdiff(pl, 'dev');
        for i = 1:numel(pl)
            s.(pl{i}) = obj.(pl{i});
        end
        
      
    end
    
    
  end % methods

  methods (Access = private)
      % dependent property set methods
%       function setdia(o,value)
%           IOPort('Write', o.dev, ['DIA ' num2str(value) o.commandSeparator],0); %#ok<*MCSUP>
%           % Refresh currentDiameter reported by pump
%           WaitSecs(0.1);
%           IOPort('Write', o.dev, ['DIA' o.commandSeparator],0);
%           WaitSecs(0.1);
%           a = char(IOPort('Read', o.dev,1,14));
%           o.diameter = str2double(a(10:end));
%       end % set.diameter
% 
%     function setvol(o,value)
%         
%         IOPort('Write', o.dev, ['VOL ' num2str(value) ' ' o.units o.commandSeparator],0);%0.05
%         o.volume = value;
%         
%     end % set.volume
% 
%     function setrate(o,value)
%         IOPort('Write', o.dev, ['RAT ' num2str(value) ' MH ' o.commandSeparator],0);
%         o.rate = value;
%     end % set.rate
%     
%     
      function err = setdia(o,d) % set syringe diameter
          err = o.sndcmd(sprintf('DIA %5g',d));
      end
      
      function err = setvol(o,d) % set dispensing volume
          err = o.sndcmd(sprintf('VOL %5g',d));
      end
      
      function err = setrate(o,d) % set dispensing rate
          err = o.sndcmd(sprintf('RAT I %5g MM',d)); % 'I' set rate for infusion ONLY!
      end

    function err = setdir(o,d) % set pump direction
        switch d
            case 0 % infuse
                err = o.sndcmd('DIR INF');
                %         case 1, % withdraw
                %           err = o.sndcmd('DIR WDR');
            otherwise
                warning('MARMOVIEW:NEWERA','Invalid pump direction %i.',d);
        end
    end
    
    function err = run(o) % start the pump
        err = o.sndcmd('RUN');
    end
    
    function err = stop(o) % stop the pump
        err = o.sndcmd('STP');
    end
    
    function err = clrvol(o,d) % clear dispensed/withdrawn volume
        switch d
            case 0 % clear infused volume
                err = o.sndcmd('CLD INF');
            case 1 % clear withdrawn volume
                err = o.sndcmd('CLD WDR');
            otherwise
                warning('MARMOVIEW:NEWERA','Invalid pump direction %i.', d);
        end
    end
    
    function [infu,wdrn] = qryvol(o) % query dispensed/withdrawn volume
        [err,~,msg] = o.sndcmd('DIS');
        assert(err == 0);
        
        % note: pump responds with [I <float> W <float> <volume units>] where
        %       "I <float>" refers to the infused volume and "W <float>" refers
        %       to the withdrawn volume
        
        pat = 'I\s*(?<infu>[\d\.]{5})\s*W\s*(?<wdrn>[\d\.]{5})\s*(?<units>[A-Z]{2})';
        tokens = regexp(msg,pat,'names');
        
        % note: infu and wdrn should be returned in ml, however, if
        %       diameter <= 14.0mm, the pump returns the volumes in
        %       microliters (unless the default units have been over-ridden).
        switch upper(tokens.units)
            case 'ML' % milliliters
                infu = str2double(tokens.infu);
                wdrn = str2double(tokens.wdrn);
            case 'UL' % microliters
                infu = str2double(tokens.infu)/1e3; % milliliters
                wdrn = str2double(tokens.wdrn)/1e3;
            otherwise
                warning('MARMOVIEW:NEWERA','Unknown volume units ''%s''.', tokens.units);
        end
    end
    
    function err = beep(o,n) % sound the buzzer
        if nargin < 2
            n = 1;
        end
        err = o.sndcmd(sprintf('BUZ 1 %i',n));
    end
    
    function [err,status,msg] = sndcmd(o,cmd) % send command to the pump
        
        if isempty(o.dev)
            err = 'not valid';
            status ='not valid';
            msg = 'not valid device';
            return
        end
        flushin(o);
        
%         cmd_ = sprintf('%02i %s',o.address,cmd);
        cmd_ = [cmd o.commandSeparator];
        IOPort('Write',o.dev,cmd_);
        
        if nargout < 1
            return
        end
        
        WaitSecs(0.100); % <-- FIXME: need to figure out how to remove the need for this
        
        % the response from the pump looks like this:
        %
        %   [STX][Addr][Prmpt][Data][ETX]
        %
        % e.g., '00S10.00MM' <-- Addr = 00, Prmpt = S, Data = 10.00MM
        %
        % STX = Start of text (0x02)
        % ETX = End of text (0x03)
        %
        % [Prmpt] is one of:
        %
        %   'S' <-- Stopped
        %   'I' <-- Infusing
        %   'P' <-- Paused
        %   'A' <-- Alarm
        %
        % if there is an error, [Data] contains '?[Code]' where [Code] is one
        % of:
        %
        %   ''   <--  not recognised
        %   'NA' <--  not applicable
        %   'OOR' <-- out of range
        %
        % a command with no payload acts as a query:
        %
        %   DIA returns [Data] like '20.00'
        %   RAT returns [Data] like '10.00MM'
        %   VOL returns [Data] like '5.000ML'
        %   DIR returns [Data] like 'INF' or 'WDL'(?)
        n = IOPort('BytesAvailable', o.dev);
        msg = IOPort('Read',o.dev,[],n);
        msg = char(msg(2:end-1)); % drop [STX] and [ETX]
        
        pat = '(?<addr>[\d]{2})\s*(?<prmpt>[A-Z]{1})\s*(?<msg>\S*)';
        tokens = regexp(msg,pat,'names');
        
        err = 0;
        if isempty(tokens) || any(tokens.msg == '?') % test for error
            err = 1;
        end
        
        status = -1;
        switch tokens.prmpt
            case 'S' % stopped
                status = 0;
            case 'I' % infusing
                status = 1;
            case 'P' % paused
                status = 3;
            case 'A' % alarm, msg contains the alarm code
                warning('MARMOVIEW:NEWERA','Pump alarm code: %s!\nCheck diameter, rate and volume...',tokens.msg);
                o.sndcmd('AL0'); % clear the alarm?
                status = 4;
            otherwise
                warning('MARMOVIEW:NEWERA','Unknown prompt ''%s'' returned by the New Era syringe pump.',tokens.prmpt);
        end
        
        msg = tokens.msg;
    end
    
    function flushin(o)
        % read and discard the contents of the serial port input buffer...
%         IOPort('Flush',o.dev);
        IOPort('Write', o.dev, o.commandSeparator);  
        while IOPort('BytesAvailable', o.dev) > 0
            IOPort('Read', o.dev);
            WaitSecs(.1);
        end
    end
    
  end % private emethods
  
  methods(Static)
      function obj = loadobj(s)
          if isstruct(s)
              newObj = marmoview.newera;
              fl = fieldnames(s);
              for i = 1:numel(fl)
                  newObj.(fl{i}) = s.(fl{i});
              end
              obj = newObj;
          else
              obj = s;
          end
      end
  end

end % classdef
