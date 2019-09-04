% class for delivering auditory feedback
% this plays a gunshow.wav file as an auditory stimulus - Jude

classdef sound_gunshot < handle
  
  properties (SetAccess = private, GetAccess = private)
    fixbreak_sound;    % audio of fix break sound
    fixbreak_sound_fs; % sampling rate of sound
  end 
   
  methods
    function o = sound_gunshot(o,varargin),  
        %********** load in a fixation error sound ************
        [y,fs] = audioread(['SupportData',filesep,'gunshot_sound.wav']);
        y = y(1:floor(size(y,1)/3),:);  % shorten it, very long sound
        o.fixbreak_sound = y;
        o.fixbreak_sound_fs = fs;
        %****************
    end
    
    function deliver(o,varargin),
        sound(o.fixbreak_sound,o.fixbreak_sound_fs);
    end
    
    function r = report(o),
      r = [];
    end
  end % methods
  
end % classdef
