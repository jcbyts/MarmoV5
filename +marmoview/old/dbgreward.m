% a minimal instantiation of the @liquid interface
%
% an @dbgreward object produced sound rather deliver a liquid reward...
% this can be useful when debugging reward delivery or can be used when a
% rig has no mechanism for delivering liquid rewards, e.g., because you're
% developing or debugging your stimulus on your laptop

% 30-05-2016 - Shaun L. Cloherty <s.cloherty@ieee.org>

classdef dbgreward < marmoview.liquid,
  properties,
    volume@double = 0.0;
    soundbit = [];
  end
  
  methods
    function o = dbgreward(h,varargin),
      o = o@marmoview.liquid(h);
      o.soundbit  = stimuli.sound(h);
    end
    
    function deliver(o),
      o.soundbit.deliver();
    end
    
    function r = report(o),
      r = struct([]);
    end
  end
end
