function [L num xs ys zs] = gft_calc(un, vn, wn, thresh, niter)
verbose = 1;
%%%% Gradient flow tracking ------ vectorized
[xs,ys, zs] = meshgrid(1:size(un,2), 1:size(un,1), 1:size(un,3));

maxxr = max(xs(:));maxyr = max(ys(:));maxzr = max(zs(:));
%Ix = sub2ind(size(xs), ys(:), xs(:), zs(:));

%%% initalize converting subscripts to linear indices
siz = size(xs);
k = [1 cumprod(siz(1:end-1))];%Compute linear indices


%%% Do the actual stepping -- this is in principle data-parallel and should run on GPU

for ix = 1:niter
    if verbose, disp(['Gradient flow tracking iteration:  ' num2str(uint16(ix)) '  of  '  num2str(uint16(niter))]);end
    Vx = 1 + (ys(:)-1)*k(1) + (xs(:)-1)*k(2) + (zs(:)-1)*k(3);  %% this replaces sub2ind
    NV = sqrt((un(Vx).^2+vn(Vx).^2+wn(Vx).^2));
    NV(NV==0) = 1;      %% set to one to avoid nan appearing in the xs ys and zs matrices
    
    xs(:) = xs(:)+ round(un(Vx)./NV);
    xs(xs>=maxxr) = maxxr;
    xs(xs<=0) = 1;
    
    ys(:) = ys(:)+ round(vn(Vx)./NV);
    ys(ys>=maxyr) = maxyr;
    ys(ys<=0) = 1;
    
    zs(:) = zs(:)+ round(wn(Vx)./NV);
    zs(zs>=maxzr) = maxzr;
    zs(zs<=0) = 1;
    
end
save result_gft_iter20 xs ys zs;
if verbose, disp('End of GFT calculation');end
%% clean the results from the voxels that drifted to the edges
% and the voxels that should not have been tracked. This effectively creates
% an imaginary sink ( "sink" sink) which will be deleted later
V = mat2gray(double(sqrt(un.^2 + vn.^2 + wn.^2)));
index = find(V<thresh);
val = 1;
xs(index) = val;ys(index) = val; zs(index) = val;

cr = 3; % clip range for edges. Sinks within the range get deleted
zs(xs>=(maxxr-cr)) = val;ys(xs>=(maxxr-cr)) = val;xs(xs>=(maxxr-cr)) = val;
zs(ys>=(maxyr-cr)) = val;xs(ys>=(maxyr-cr)) = val;ys(ys>=(maxyr-cr)) = val;
xs(zs>=(maxzr-cr)) = val;ys(zs>=(maxzr-cr)) = val;zs(zs>=(maxzr-cr)) = val;
zs(xs<=cr) = val;ys(xs<=cr) = val;xs(xs<=cr) = val;
zs(ys<=cr) = val;xs(ys<=cr) = val;ys(ys<=cr) = val;
xs(zs<=cr) = val;ys(zs<=cr) = val;zs(zs<=cr) = val;


%%%%%%%%%%% let's determine the number of sinks
mosaic = zeros(size(xs));
Vx = sub2ind(size(xs), ys(:), xs(:),zs(:));
mosaic(Vx) = 1; % this will set sink coordinates to 1
mosaic(1) = 0;  % delete the "sink" sink.
L = bwlabeln(mosaic, 26);   % fuses close-by sinks
L(val,val,val) = 0;
num = max(L(:));    % determines the number of sinks
if verbose,disp(['Initial (over)estimate of number of sinks is: ' num2str(num)]);end

