
%% Open Marmoview screen with parameters from Forage protocol
sca % clear any open windows

[S,P] = Forage2();
A = marmoview.openScreen(S, struct());

winPtr = A.window;
%% Update 
P.snoisediam = inf; % diameter of noise
P.range = 127;

        
grat = stimuli.grating_drifting(winPtr, ...
    'numDirections', 16, ...
    'minSF', 1, ...
    'numOctaves', 1, ...
    'pixPerDeg', S.pixPerDeg, ...
    'speeds', [1, 5, 8, 10]/S.frameRate, ...
    'position', [500 250], ...
    'screenRect', S.screenRect, ...
    'diameter', 10, ...
    'durationOn', 50, ...
    'durationOff', 40, ...
    'isiJitter', 10, ...
    'contrasts', 0.25, ...
    'randomizePhase', true);


%%
grat.beforeTrial()
grat.updateTextures()
%%
t0 = GetSecs;
while GetSecs < t0 +5
grat.afterFrame()
grat.beforeFrame()
% 
Screen('Flip', winPtr, 0);
end

%%
% grat.cpd = 1;
% grat.contrast = .5;
% grat.stimValue = 1;
grat.tex.cpd = 1;
grat.phase = 0;
grat.tex.phase = grat.tex.phase + 50;
grat.beforeFrame();
Screen('Flip', winPtr, 0);
%% close screen if done
sca

