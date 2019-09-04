function close()
%close Datapixx at the end of an experiment.
% this is really a barebones version until I can figure out everything
% PLDAPS is using it to do, JM 10/7/2018

% datapixx.close()
%
% datapixx.init is a function that turns off the DATAPIXX

    if Datapixx('IsReady')
        Datapixx('Close');
    end
  
end
