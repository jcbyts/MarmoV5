function A=openScreen(S,A)
% OPENSCREEN Opens PTB window with parameters specified in S

% Initialize open GL settings
featureLevel = 0; % use the 0-255 range in psychtoolbox (1 = 0-1)
PsychDefaultSetup(featureLevel);

% disable ptb welcome screen
Screen('Preference','VisualDebuglevel',3);

% close any open windows
Screen('CloseAll');

% setup the image processing pipeline for ptb
PsychImaging('PrepareConfiguration');

% PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');
PsychImaging('AddTask','General','FloatingPoint32BitIfPossible', 'disableDithering',1);

% Applies a simple power-law gamma correction
PsychImaging('AddTask','FinalFormatting','DisplayColorCorrection','SimpleGamma');

% create the ptb window...
if isfield(S,'DummyScreen') && S.DummyScreen
  [A.window, A.screenRect] = PsychImaging('OpenWindow',0,S.bgColour,S.screenRect);
else    
  [A.window, A.screenRect] = PsychImaging('OpenWindow',S.screenNumber,S.bgColour);
  
  % Add gamma correction
  PsychColorCorrection('SetEncodingGamma',A.window,1/S.gamma);
end

A.frameRate = FrameRate(A.window);

% bump ptb to maximum priority
A.priorityLevel = MaxPriority(A.window);

% set alpha blending/antialiasing etc.
Screen(A.window,'BlendFunction',GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

% some propixx specific commands

if isfield(S, 'DataPixx') && S.DataPixx 
    if Datapixx('IsPropixx')
        Datapixx('Open');
        Datapixx('EnablePropixxRearProjection');
        Datapixx('EnablePropixxLampLed');
        Datapixx('RegWr');
    end
end