function write_to_avi(im1, fn)
%%%% matrix to avi using matlab's b videowriter
im1 = uint8(floor(mat2gray(im1) * 255));
v = VideoWriter(fn, 'Grayscale AVI');
open(v)
writeVideo(v,im1);
for k = 1:size(im1,3)
   writeVideo(v,im1(:,:,3));
end

close(v);