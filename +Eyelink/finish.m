function finish(tracker_info)
%eyelink.finish    stop recording on eyelink
%
% p = eyelink.finish(p)
% eyelink.finish stops recording and closes the currently open edf file.


if tracker_info.eyelink_use && Eyelink('IsConnected')
    edfFile = tracker_info.edfFile;
    dirs = tracker_info.edfFileLocation;
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    % download data file
    if tracker_info.saveEDF
        try
           result = Eyelink('Receivefile',edfFile, fullfile(dirs,edfFile));
           if(result==-1)
              warning('eyelink:EyelinkGetFiles', ['receiving ' edfFile '.edf file failed!']);
           else
               fprintf('EDF file received: %s.edf .', edfFile);
           end
        catch rdf
            fprintf('Problem receiving EDF data file ''%s''\n', edfFile );
            rethrow(rdf);
        end
    end
    Eyelink('Shutdown')
end

