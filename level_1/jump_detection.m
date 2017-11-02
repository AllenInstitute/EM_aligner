function [D, I] = jump_detection(rc, nfirst, nlast, delta, scale, c)
% detects correlation coefficient using corr2 in a z stack
% within a Renderer box
% If c is not specified, the box is determined to be in the middle of the
% stack using Renderer stack bounds.
%
% c is a two-vector of points
% D is a size(c,1)x1 vector with cross correlation values
% Example
% rc.stack          = ['n_10_l_9_tfac_m9_xlfac_0_ylfac_0_xfac_2_yfac_5_deg_2'];
% rc.owner          ='hessh';
% rc.project         = 'tomoko_Santomea11172016_04_A3_T1';
% rc.service_host   = 'tem-services.int.janelia.org:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 0;
% nfirst = 1000;
% nlast = 00;
% scale = 0.1;  % scale of image box
% delta = 300;  % extent in pixels for box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if no centers are provided, calculate based on center box.
if nargin<6 || isempty(c)
    disp('Using center:');
    [Wbox_stack, box, url, minZ, maxZ] = get_slab_bounds_renderer(rc);
    [Wbox, box, url] = get_section_bounds_renderer(rc, floor(nfirst + (nlast-nfirst)/2));
    % Wbox is [x y width height] of the section L as specified in rc
    c(1) = Wbox_stack(1) + (Wbox(1) + Wbox(3)/2);
    c(2) = Wbox_stack(2) + (Wbox(2) + Wbox(4)/2);
    disp(c);
end


%disp(['Section bounds determined based on section ' num2str(floor(nfirst + (nlast-nfirst)/2))]);

if nargin<5 || isempty(scale), scale = 0.1;end
if nargin<4 || isempty(delta), delta = 300;end
if nargin<3 || isempty(nlast), nlast = maxZ;end
if nargin<2 || isempty(nfirst), nfirst = minZ;end



% itereate over centers provided by c
D = {};
for cix = 1:size(c,1)
    if ~isnan(c(cix,1))
        box_(1) = [c(cix,1) - delta];
        box_(2) = [c(cix,2) - delta];
        box_(3) = [delta*2];
        box_(4) = [delta*2];
        im_agg = [];
        zrange = nfirst:nlast;
        disp(['                         Rendering box: ' num2str(cix) ' of ' num2str(size(c,1))]);
        %parfor_progress(numel(zrange));
        parfor ix = 1:numel(zrange)
            %disp(ix);
            [im, v, url, resp_str] = get_image_box_renderer(rc, zrange(ix), box_, scale, 'kk');
            im_agg(:,:,ix) = im;
            %  parfor_progress;
        end
        %parfor_progress(0);
        I{cix} = mat2gray(im_agg);
        for ix = 2:size(I{cix},3)
            %     pause(0.3);
            %     imshow(I(:,:,ix));
            %     title(num2str(ix));
            %     drawnow;
            
            im1 = I{cix}(:,:,ix-1);
            im2 = I{cix}(:,:,ix);
            cres = corr2(im1, im2);
            if isnan(cres), cres = 0;end
            D{cix}(ix-1,1)  = cres;
            %figure;cla;imshowpair(im1, im2, 'blend');title([rc.stack ' ' num2str(D{cix}(ix-1))]);axis ij;drawnow;pause(0.3);
        end
    else
        D{cix} = [];
        I{cix} = [];
    end
end

% figure;plot(D);title(rc.stack);drawnow;
