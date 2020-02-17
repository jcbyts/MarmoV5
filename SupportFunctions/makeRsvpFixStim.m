

imdir = '~/Desktop/GoogleImages/';
imfiles = dir(fullfile(imdir, '*.png'));

num = numel(imfiles);
imcounter=1;
sz = [200 200];

a = load('SupportData/MarmosetFaceLibrary.mat');
facefields = fieldnames(a);
nfaces = numel(facefields);

ims = zeros(sz(1), sz(2), nfaces+num);

for ii = 1:num
    
    im = imread(fullfile(imfiles(ii).folder, imfiles(ii).name));
    im = mean(im,3);

    im = double(im);
    im2 = imgaussfilt(im, 1) - imgaussfilt(im, 10);

    im2 = im2./rms(im2(:));
    im2 = im2 * .5*127;
    im2 = im2 + 127;

    im2 = imresize(im2, sz);

    ims(:,:,ii) = im2;
    
end    

for ii = 1:nfaces
    
    im = a.(facefields{ii});
    im = mean(im,3);

    im = double(im);
    im2 = imgaussfilt(im, 1) - imgaussfilt(im, 10);

    im2 = im2./rms(im2(:));
    im2 = im2 * .5*127;
    im2 = im2 + 127;

    im2 = imresize(im2, sz);
    
    ims(:,:,ii+num) = im2;
end
   

inds = randsample(1:(nfaces+num), nfaces+num, false);
figure(1); clf
for jj = inds(:)'
    
    im2 = ims(:,:,jj);
    imagesc(im2);
    drawnow
    
    pause(0.064)
   
end

%%
S = struct();
for jj = 1:numel(inds)
    im2 = ims(:,:,inds(jj));
    field = sprintf('im%02.0f', jj);
    S.(field) = uint8(repmat(im2, 1, 1, 3));
end


%%

save('rsvpFixStim.mat', '-v7', '-struct', 'S')
    
    
    