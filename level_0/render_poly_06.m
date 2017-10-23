function [imt, Wbox, imlabel, M] = render_poly_06(tiles, scale, Wbox, flag, stack)
%% Short description for polynomial case:
%     Renders images with polynomial transformation up to third degree.
%    Transformations are provided in the tform field of individual tiles in the "tiles" array.
%    If  a images.geotrans.PolynomialTransformation2D transform object is detected,
%    a basis matrix A is constructed and populated with the basis functions in the same order as
%    the corresponding coefficients are stored in images.geotrans.PolynomialTransformation2D
%    This order is given by the following example:
%    Example: For a second order polynomial u (or v) is given by:
%    u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2
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
verbose = 0;
if verbose, disp(['Original number of tiles: ' num2str(numel(tiles))]);end
%%% determine which tiles we actually need for this box
%%%% filter out the tiles that are not included in the box
%%%% (with a margin equal to Wout and Hout
if nargin<5, margin_cutoff = 15;end
intensity_correction = 0;

if nargout>=3, intensity_correction = 1;end


if flag
    L = Msection();
    L.tiles = tiles;
    tiles = tiles_in_box(L, Wbox);
    if verbose,disp(['Filtered number of tiles: ' num2str(numel(tiles))]);end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ims = get_image(tiles(1)); % get image and rescale
tiles(1).stack = stack;
ims = get_image(tiles(1));
ims = imresize(ims, scale);






%%%%%% uncomment if all images are same size
% Nrs = size(ims,1);   % number of rows for source images
% Ncs = size(ims,2);   % number of columns (width) of source images
% [xsource, ysource] = meshgrid(1:Ncs, 1:Nrs);
% xsource = xsource/scale;
% ysource = ysource/scale;
% if verbose,disp([min(xsource(:)) max(xsource(:)) min(ysource(:)) max(ysource(:))]);end
% % generate the basis matrix A for a second degree polynomial
% % for up to third degree
% % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
% %     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
% 
% a1 = ones(length(xsource(:)),1);
% a2 = xsource(:);
% a3 = ysource(:);
% a4 = xsource(:).*ysource(:);
% a5 = xsource(:).*xsource(:);
% a6 = ysource(:).*ysource(:);
% a7 = a5(:).*ysource(:);
% a8 = xsource(:).*a6(:);
% a9 = a5(:).*xsource(:);
% a10 = a6(:).*ysource(:);
% A = [a1 a2 a3 a4 a5 a6 a7 a8 a9 a10];







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
box = cell(numel(tiles),1);
imm = cell(numel(tiles),1);
if verbose,disp('Starting parfor loop'); end % parfor speeds up processing linearly by 12 if Matlab earlier than 2014a, 16/32 otherwise
filter = 1;
tic
if verbose, disp('--------------- Using render_poly_06 -------------');end
parfor ix  = 1:numel(tiles)
    try
        tic
        % sosi
        tiles(ix).stack = stack;
        %tim = get_image_renderer(tiles(ix), scale, filter);
        tim = get_image(tiles(ix));
        ims = double(tim); % 
        ims(mat2gray(ims)<0.05) = 0;
        ims = imresize(ims, scale); % corresponds to the source grid values in xsource and ysource
        
        %%%%%%%%%%%%%% include this to allow different values for
        %%%%%%%%%%%%%% image size
        Nrs = size(ims,1);   % number of rows for source images
        Ncs = size(ims,2);   % number of columns (width) of source images
        [xsource, ysource] = meshgrid(1:Ncs, 1:Nrs);
        xsource = xsource/scale;
        ysource = ysource/scale;
        %if verbose,disp([min(xsource(:)) max(xsource(:)) min(ysource(:)) max(ysource(:))]);end
        % generate the basis matrix A for a second degree polynomial
        % for up to third degree
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
        %     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        
        
        %%% check whether we have mask information or not
        %     if ~isempty(mask_list)
        %         % apply the mask
        %         indx = find(mask_list==tiles(ix).cam,1);
        %         imm = imread(mask_fn{indx});
        %         ims = ims.*double(im2bw(imm));
        %     end
        
        %immask = double(get_mask_image(tiles(ix)));
        %if ~isempty(immask), ims = ims.*double(im2bw(immask));end
        
        
        %ims = background_filter(real(ims), 1);
        
        
        if verbose,disp(['Size source: ' num2str(size(ims,1)) ' x ' num2str(size(ims,2))]);end
        %ims = imresize(ims, scale); % corresponds to the source grid values in xsource and ysource
        
        %immask = imresize(immask, scale);
        
        if strcmp(class(tiles(ix).tform), 'affine2d')
            % where did the target coordinates come from in the source image?
            warning off;
            tform = tiles(ix).tform;
            
            if tiles(ix).fetch_local==0, 
                tform.T([1 5]) = 1;
                tform.T([2 4]) = 0;
            end
                    
            [x, y] = transformPointsInverse(tform, xgrid, ygrid); % get coordinates in undeformed image (works nicely for affine2d because invertible)
            % interpolate to generate the tile image
            if verbose,disp('render_poly:affine2d --> using cubic interpolation');end
            
            
            %             im{ix} = interp2(xsource, ysource, ims, x,y, 'cubic');
            %             imm{ix} = interp2(xsource, ysource, immask, x,y, 'nearest');
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            ima = interp2(xsource, ysource, ims, x,y, 'cubic');
            %             if ~isempty(immask)
            %             imb = interp2(xsource, ysource, immask, x,y, 'cubic');
            %             imb(isnan(imb)) = 0;
            %             imb(imb<250) = 0;
            %             imb(imb>0.0) = 1.0;
            %             ima(imb<0.5) = nan;
            %             %%% store only the relevant block and store block upperleft
            %             %%% corner and lower right
            indx = find(~isnan(ima));
            [r, c] = ind2sub(size(imt), indx);
            box{ix} = [min(r) max(r) min(c) max(c)];
            im{ix} = ima(min(r):max(r), min(c):max(c));
            %             else
            %                 im{ix} = ima;
            %             end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        elseif strcmp(class(tiles(ix).tform), 'images.geotrans.PolynomialTransformation2D')
            %%%%%%%%%%%%% include calculation of A here to allow different
            %%%%%%%%%%%%% image sizes
            a1 = ones(length(xsource(:)),1);
            a2 = xsource(:);
            a3 = ysource(:);
            a4 = xsource(:).*ysource(:);
            a5 = xsource(:).*xsource(:);
            a6 = ysource(:).*ysource(:);
            a7 = a5(:).*ysource(:);
            a8 = xsource(:).*a6(:);
            a9 = a5(:).*xsource(:);
            a10 = a6(:).*ysource(:);
            A = [a1 a2 a3 a4 a5 a6 a7 a8 a9 a10];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            tdim = (tiles(ix).tform.Degree + 1) * (tiles(ix).tform.Degree + 2)/2;
            disp(['Peforming higher-than-one degree polynomial transformation image rendering for tile: ' num2str(ix)]);
            
            xtarget = A(:,1:tdim)*tiles(ix).tform.A(:); % perform forward transform to get the target coordinates (not on a grid)
            ytarget = A(:,1:tdim)*tiles(ix).tform.B(:); % note: you still needed xsource and ysource to generate A
            
            %                     disp('Using scatteredInterpolant --- 3x slower than griddata but more accurate and gives better images');
            %                    F = scatteredInterpolant(xtarget,ytarget,ims(:));
            %                     im{ix} = F(xgrid,ygrid);%F.Method = 'nearest';im{ix} = F({Nctvec, Nrtvec});
            %
            if verbose ==2, disp('Using griddata');end
            ima= griddata(xtarget, ytarget, ims(:), xgrid, ygrid);
            
            %%% store only the relevant block and store block upperleft
            %           %%% corner and lower right
            indx = find(~isnan(ima));
            [r, c] = ind2sub(size(imt), indx);
            box{ix} = [min(r) max(r) min(c) max(c)];
            im{ix} = ima(min(r):max(r), min(c):max(c));
            
            
            %imm{ix} = griddata(xtarget, ytarget, immask(:), xgrid, ygrid);
            
            
            if verbose==2, disp(['Finished interpolating tile: ' num2str(ix)]);end
            
        else
            disp('unknown transformation');
        end
    catch error_rendering
        warning('error rendering');
        disp(error_rendering);
        im{ix} = [];
        box{ix} = [];
    end
end
toc
warning on;

if verbose==2, disp('finished all interpolation jobs');end


%% %%%%%%%%%%%%  Construct the final image from all images in im
thresh = 0;
imt(:) = 0;
tempim = zeros(size(imt));
M = [];
%M = zeros(size(imt,1), size(imt,2), numel(tiles), 'double');
for ix = 1:numel(tiles)
    if ~isempty(im{ix})
        ima = im{ix};
        %%%%%%%%%%%%%
%         level = 0.05;
%         mask1 = im2bw(mat2gray(ima),level);
%         se1 = strel('disk',thresh);
%         se2 = strel('disk',ceil(thresh/2));
%         mask2 = imclose(mask1,se1);
%         mask2 = imerode(mask2,se2);
%         ima = ima.*mask2;
        %%%%%%%%%%%%%%
        b = box{ix};
        tempim(:) = 0;
        tempim(b(1):b(2), b(3):b(4)) = ima;
        tempim(mat2gray(tempim)<0.1) = nan;
        tempim(mat2gray(tempim)==1.0) = nan;
        imt(~isnan(tempim)) = tempim(~isnan(tempim));
        %M(:,:,ix) = (mat2gray(imt));
    end
end
imt = mat2gray(imt);
%M = mat2gray(M);
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









































