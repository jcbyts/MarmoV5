function ptbProceduralGabor(drawRects)



%% need these values
disableNorm = 1; % don't normalize the gabor by the gaussian sigma
modulateColor = [0 0 0 0]; %  zeros means don't offset the background (depends on blend function)
contrastPreMultiplicator = 0.5; % 0.5 scales max response to contrast is interpretable

rect = [0 0 90 90];
orientation = 90;
phase = 0;
transparent = 1;
freq = 0.04;
sigma = 20;

tiltAngle = 90 + orientation;

% Constants we need (as they are called in the GLSL shader)
twopi     = 2.0 * 3.141592654;
sqrtof2pi = 2.5066282746;

% Conversion factor from degrees to radians:
deg2rad = 3.141592654 / 180.0;

auxParameters0 = [-phase+90, freq, sigma, transparent, 1, 0, 0, 0];

%%
%     /* Don't pass real texture coordinates, but ones corrected for hardware offsets (-0.5,0.5) */
%     /* and so that the center of the gabor patch has coordinate (0,0): */
% gl_TexCoord[0] = gl_MultiTexCoord0 - vec4(Center, 0.0, 0.0) + vec4(-0.5, 0.5, 0.0, 0.0);

% Contrast value is stored in auxParameters0(3)
Contrast = auxParameters0(3);

% Convert Angle and Phase from degrees to radians:
Angle = deg2rad * tiltAngle;
Phase = deg2rad * auxParameters0(1);

% Precalc a couple of per-patch constant parameters:
FreqTwoPi = auxParameters0(2) * twopi;
SpaceConstant = auxParameters0(3);
Expmultiplier = -0.5 / (SpaceConstant * SpaceConstant);

% Conditionally apply non-standard normalization term iff disableNorm == 0.0 */
mc = disableNorm + (1.0 - disableNorm) * (1.0 / (sqrtof2pi * SpaceConstant));

% Premultiply the wanted Contrast to the color:
baseColor = modulateColor * mc * Contrast * contrastPreMultiplicator;


%%

% two ways
[xx, yy] = meshgrid(-50:50);
pos = [xx(:) yy(:)];

% Compute (x,y) distance weighting coefficients, based on rotation angle:
% Note that this is a constant for all fragments, but we can not do it in
% the vertex shader, because the vertex shader does not have sufficient
% numeric precision on some common hardware out there.
coeff = [cos(Angle), sin(Angle)] * FreqTwoPi;

% Evaluate sine grating at requested position, angle and phase: */
sv = sin(pos*coeff' + Phase);

% Compute exponential hull for the gabor:
ev = exp(sum(pos.^2,2) * Expmultiplier);

% Multiply/Modulate base color and alpha with calculated sine/gauss
% values, add some constant color/alpha Offset, assign as final fragment
% output color:
a = (ev .* sv);
gl_FragColor = a; % * baseColor ;

figure(1); clf
imagesc(reshape(gl_FragColor, size(xx)))
