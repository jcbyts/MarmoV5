w = 1280;
h = 720;

spatial_scale = 3;

% Start with gaussian white noise (on larger square)
L = max([w h]);
noise_stim = randn(num_frames,L,L);

% 2-D Gaussian mask
xs=(0:(L-1))-L/2;  %%%%%%%%%%%%%%%
r2s = xs'.^2*ones(1,L) + ones(L,1)*xs.^2;
rad1 = 2*L/pi/spatial_scale;
mask1 = exp(-r2s/(2*rad1^2));
mask1 = mask1/max(mask1(:));



%im1 = baserand2(:,:,k);
im1 = squeeze(noise_stim(k,:,:));
manip1 = fftshift(fft2(im1));
% figure; imagesc(fx,fy,log(abs(manip1))); colorbar;
manip2 = mask1.*manip1;
im2 = ifft2(ifftshift(manip2)); %%%%%%%%%%



imagesc(im2)
% imwrite(uint8(im2*127.5 + 127.5), 'cloud1.png', 'PNG')

