

%% open Screen
S = MarmoViewRigSettings;
S.screenRect = [0 0 600 500];
A = marmoview.openScreen(S);

%%

grat = stimuli.grating_procedural(A.window);

grat.position = A.screenRect(3:4)/2;
grat.screenRect = A.screenRect;
grat.pixperdeg = S.pixPerDeg;

grat.cpd = 0;
grat.radius = 100; % in pixels (also note, this is the diameter, I think)
grat.orientation = 90; % in degrees
grat.phase = 0;

grat.range = 127; % color range
grat.square = false; % if you want a hard aperture
grat.gauss = true;
grat.bkgd = S.bgColour;
grat.transparent = 0.5; % effectively Michelson contrast / 2 -- again, worth checking

grat.updateTextures()
grat.stimValue = 1;
grat.beforeFrame()


Screen('Flip', A.window)


%% interact with mouse input
[x0,y0] = GetMouse();

for i = 1:1000
    grat.position = grat.position + randn(1,2)*2;
    
    grat.beforeFrame()
    Screen('Flip', A.window)
end