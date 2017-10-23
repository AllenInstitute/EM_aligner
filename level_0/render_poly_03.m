function [imt, Wbox, imlabel, A] = render_poly_03(tiles, scale, Wbox, flag, margin_cutoff, mask_list, mask_fn, A)
%% use fourier series expansion to transform images
%   The basis functions are evaluated at the grid points corresponding to source images

%   To obtain the u coordinate for points in the target image we simply apply the forward transform (matrix multiply)
%       u = A * a, where "a" is the vector of coefficients from a1 to a5 specific to the u coordinate.
%   Do the same for v. Matlab stores these vectors in its images.geotrans.PolynomialTransformation2D class as "A" and "B"
%  please do not confuse tform.A with the basis matrix A. I perform the simple forward transform myself and don't use the Matlab functions
%  s
%   The target points are not on the target grid, and need to be interpolated onto this grid. For this purpose I have a choice of two
%    interpolation functions. "griddata" is faster but not very accurate.
%% render images defined in tile objects array "tiles" to a montage defined by "box" world coordinates
% box = [x y width height]
% flag==1 forces tile filtering to within the Wbox
% if the tiles transformation class is affine2d or it is of degree 1, then
% this is a special case handled by the function render_affine ---> below
% If the transformation is a polynomial of degree higher than 1, then
% render by forward transform (no inverse because of the "polynomial"
% inversion difficulty)
% Example: see below (at end of the file)
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 1;
if verbose, disp(['Original number of tiles: ' num2str(numel(tiles))]);end
%%% determine which tiles we actually need for this box
%%%% filter out the tiles that are not included in the box
%%%% (with a margin equal to Wout and Hout
if nargin<5, margin_cutoff = 15;end
if nargin<8, A = [];end
intensity_correction = 0;

if nargout>=3, intensity_correction = 1;end


if flag
    L = Msection();
    L.tiles = tiles;
    tiles = tiles_in_box(L, Wbox);
    if verbose,disp(['Filtered number of tiles: ' num2str(numel(tiles))]);end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ims = get_image(tiles(1)); % get image and rescale
ims = imresize(ims, scale);
Nrs = size(ims,1);   % number of rows for source images
Ncs = size(ims,2);   % number of columns (width) of source images
[xsource, ysource] = meshgrid(1:Ncs, 1:Nrs);
xsource = xsource/scale;
ysource = ysource/scale;
if verbose,disp([min(xsource(:)) max(xsource(:)) min(ysource(:)) max(ysource(:))]);end
% generate the basis matrix A for a second degree polynomial
% for up to third degree
% u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
%     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3


if isempty(A)
%% generate fourier series basis
if strcmp(class(tiles(1).tform), 'images.geotrans.PolynomialTransformation2D')
    a1 = ones(length(xsource(:)),1);
    a2 = xsource(:);
    a3 = ysource(:);
    a4 = xsource(:).*ysource(:);
    a5 = xsource(:).*xsource(:);
    a6 = ysource(:).*ysource(:);
    a7 = xsource(:).*xsource(:).*ysource(:);
    a8 = xsource(:).*ysource(:).*ysource(:);
    a9 = xsource(:).*xsource(:).*xsource(:);
    a10 = ysource(:).*ysource(:).*ysource(:);
    A = [a1 a2 a3 a4 a5 a6 a7 a8 a9 a10];
end
if strcmp(class(tiles(1).tform), 'nonlin2d')
    disp('Generating Fourier basis');
    x = xsource(:);
    y = ysource(:);
    nmax = tiles(1).tform.N;
    mmax = tiles(1).tform.M;
    a = 1;
    b = 1;
    ncoeff = (nmax+1) * (mmax+1);
    basf = zeros(size(x,1), ncoeff);
    counter = 1;
    for n = 0:nmax
        for m = 0:mmax
            %disp([n m]);
            thetax = n*x/a;
            thetay = m*y/b;
            basf(:,counter) = cos(thetax) .* cos(thetay);counter = counter + 1;
            basf(:,counter) = sin(thetax) .* cos(thetay);counter = counter + 1;
            basf(:,counter) = cos(thetax) .* sin(thetay);counter = counter + 1;
            basf(:,counter) = sin(thetax) .* sin(thetay);counter = counter + 1;
        end
    end
    
    
    A = basf;
end
end
%% loop over tiles, project into the target space and interpolate onto the output image grid
imt = zeros(ceil(Wbox(4)*scale), ceil(Wbox(3)*scale)); % this is the target image ---> initialize to zero

if intensity_correction,
    imlabel = zeros(ceil(Wbox(4)*scale), ceil(Wbox(3)*scale));  % in case of intensity correction we need to also generate a label image
end
% define the grid values for generating the output image
wb1 = Wbox(1);
wb2 = Wbox(2);
[Nrt, Nct] = size(imt);
[xgrid, ygrid] = meshgrid(1:Nct, 1:Nrt);
xgrid = (xgrid/scale + wb1);
ygrid = (ygrid/scale + wb2);        % this grid is in output world coordinates with a grid resolution equivalent to the required target image imt

Nctvec = (1:Nct)/scale + wb1;
Nrtvec = (1:Nrt)/scale + wb2;
 %disp([min(xgrid(:)) max(xgrid(:)) min(ygrid(:)) max(ygrid(:))]);

im = cell(numel(tiles),1);

if verbose,disp('Starting parfor loop'); end % parfor speeds up processing linearly by 12 if Matlab earlier than 2014a, 16 otherwise

tic
for ix  = 1:numel(tiles)
    tic
    ims = mat2gray(get_image(tiles(ix))); % get actual image and rescale
    %%% check whether we have mask information or not
    if ~isempty(mask_list)
        % apply the mask
        indx = find(mask_list==tiles(ix).cam,1);
        imm = imread(mask_fn{indx});
        ims = ims.*double(im2bw(imm));
    end

    if verbose,disp(['Size source: ' num2str(size(ims,1)) ' x ' num2str(size(ims,2))]);end
    ims = imresize(ims, scale); % corresponds to the source grid values in xsource and ysource
    

    if strcmp(class(tiles(ix).tform), 'affine2d') 
        % where did the target coordinates come from in the source image?
        warning off;
        [x, y] = transformPointsInverse(tiles(ix).tform, xgrid, ygrid); % get coordinates in undeformed image (works nicely for affine2d because invertible)
         % interpolate to generate the tile image
        if verbose,disp('render_poly:affine2d --> using cubic interpolation');end
        im{ix} = interp2(xsource, ysource, ims, x,y, 'cubic');
        
    elseif strcmp(class(tiles(ix).tform), 'images.geotrans.PolynomialTransformation2D')
        
        tdim = (tiles(ix).tform.Degree + 1) * (tiles(ix).tform.Degree + 2)/2;
        disp(['Peforming second degree polynomial transformation image rendering for tile: ' num2str(ix)]);
        
        xtarget = A(:,1:tdim)*tiles(ix).tform.A(:); % perform forward transform to get the target coordinates (not on a grid)
        ytarget = A(:,1:tdim)*tiles(ix).tform.B(:); % note: you still needed xsource and ysource to generate A
        
        %         disp('Using scatteredInterpolant --- 3x slower than griddata but more accurate and gives better images');
        %        F = scatteredInterpolant(xtarget,ytarget,ims(:));
        %         im{ix} = F(xgrid,ygrid);%F.Method = 'nearest';im{ix} = F({Nctvec, Nrtvec});
        %
        if verbose ==2, disp('Using griddata');end
        im{ix} = griddata(xtarget, ytarget, ims(:), xgrid, ygrid);
        
        
        if verbose==2, disp(['Finished interpolating tile: ' num2str(ix)]);end
    elseif strcmp(class(tiles(ix).tform), 'nonlin2d')
        
        %tdim = (tiles(ix).tform.Degree + 1) * (tiles(ix).tform.Degree + 2)/2;
        disp(['Peforming Fourier series transformation image rendering for tile: ' num2str(ix)]);
        
        res = transformPointsInverse(tiles(ix).tform,[xsource(:) ysource(:)], A); 
        xtarget = res(:,1);
        ytarget = res(:,2);
        
%         xtarget = A*tiles(ix).tform.T(:,1); % perform forward transform to get the target coordinates (not on a grid)
%         ytarget = A*tiles(ix).tform.T(:,2); % note: you still needed xsource and ysource to generate A
%         
        %         disp('Using scatteredInterpolant --- 3x slower than griddata but more accurate and gives better images');
        %        F = scatteredInterpolant(xtarget,ytarget,ims(:));
        %         im{ix} = F(xgrid,ygrid);%F.Method = 'nearest';im{ix} = F({Nctvec, Nrtvec});
        %
        if verbose ==2, disp('Using griddata');end
        im{ix} = griddata(xtarget, ytarget, ims(:), xgrid, ygrid);
        
        
        if verbose==2, disp(['Finished interpolating tile: ' num2str(ix)]);end
        
    else
        disp('unknown transformation');
    end

end
toc
warning on;

if verbose==2, disp('finished all interpolation jobs');end


%%%%%%%%%%%%%%  Construct the final image from all images in im
thresh = 0.0;
for ix = 1:numel(tiles)
    ima = im{ix};
    if margin_cutoff
        %% generate a mask and apply it to ima
        level = graythresh(ima);
        mask1 = im2bw(ima,level);
        
        %     se = strel('rectangle',[100 100]);
        %%% remove the crappy interpolation stuff at the boundary of the
        %%% actual image
        se1 = strel('disk',margin_cutoff);
        se2 = strel('disk',ceil(margin_cutoff/2));
        mask2 = imclose(mask1,se1);
        mask2 = imerode(mask2,se2);
        ima = ima.*mask2;
    end
    %%% add ima to the total image
    imt(ima>thresh) = ima(ima>thresh);
    if intensity_correction
        label = ix-1;
        imlabel(ima>thresh) = label;
    end
end
if nargout==0
figure;
warning off;imshow(imt);warning on;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% % %% % Example Usage:
% % % % fn = '/nobackup/flyTEM/khairy/sandbox_stacks/test_stacks/test_build_00/example_build_from_path_cell_array_2014_10_31_11_47/inlayer_results/layer_1_registered_alignBK.mat';
% % % load(fn);
% % % L = mL;
% % % t1 = L.tiles(500);
% % % t2 = L.tiles(501);
% % % t3 = L.tiles(502);
% % % t4 = L.tiles(503);
% % % 
% % % deg = 2;
% % % 
% % % t1p = t1;
% % % t2p = t2;
% % % t3p = t3;
% % % t4p = t4;
% % % 
% % % tform1  = affine2d2nonlin(t1.tform,deg);
% % % tform2  = affine2d2nonlin(t2.tform,deg);
% % % tform3  = affine2d2nonlin(t3.tform,deg);
% % % tform4  = affine2d2nonlin(t4.tform,deg);
% % % 
% % % t1p.tform = tform1;
% % % t2p.tform = tform2;
% % % t3p.tform = tform3;
% % % t4p.tform = tform4;
% % % 
% % % tiles(1) = t1p;
% % % tiles(2) = t2p;
% % % tiles(3) = t3p;
% % % tiles(4) = t4p;
% % % Wbox = [18755 20200 3000 8000];
% % % 
% % % tic
% % % scale = 0.2;
% % % im = render_poly(tiles, scale, Wbox);
% % % toc









































