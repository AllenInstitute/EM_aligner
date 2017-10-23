% The script assumes the existence of a Renderer collection (configured below)
% Dependencies:
%               - Renderer service
%               - script to generate spark_montage_scapes
%
% Calculate the full stitching (montage and alignment) of a set of sections
% Ingest this slab into a new collection
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [0] configure collections and prepare quantities
clc; clear all;
kk_clock;
nfirst = 1;
nlast  = 500;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection

rctarget_montage.stack          = ['EXP_v12_500_montage_' num2str(nfirst) '_' num2str(nlast)];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% configure rough collection
rctarget_rough.stack          = ['EXP_v12_500_rough_' num2str(nfirst) '_' num2str(nlast)];
rctarget_rough.owner          ='flyTEM';
rctarget_rough.project        = 'test';
rctarget_rough.service_host   = '10.37.5.60:8080';
rctarget_rough.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rctarget_rough.verbose        = 1;

% configure align collection
rctarget_align.stack          = ['EXP_v12_500_alignP1_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'FAFBv12_500Sections';

% configure montage-scape point-match generation
ms.service_host                 = rctarget_montage.service_host;
ms.owner                        = rctarget_montage.owner;
ms.project                      = rctarget_montage.project;
ms.stack                        = rctarget_montage.stack;
ms.first                        = num2str(nfirst);
ms.last                         = num2str(nlast);
ms.fd_size                      = '8';
ms.min_sift_scale               = '0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.scale                        = '0.15';    % normally less than 0.05 -- can be large (e.g. 0.2) for very small sections (<100 tiles)
ms.similarity_range             = '3';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nobackup/flyTEM/spark_montage';
ms.run_dir                      = ['scale_' ms.scale];
ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %

% configure fine alignment

DX = 5;   % number of divisions of the total bounding box in x
DY = 5;
scale = 0.5;
depth = 3;  % largest distance (in layers) considered for neighbors

SIFTopts.SIFTfdSize        = 8;
SIFTopts.SIFTmaxScale      = 1.0;
SIFTopts.SIFTminScale      = 0.2;
SIFTopts.SIFTsteps         = 8;

SIFTopts.matchMaxEpsilon     = 40;
SIFTopts.matchRod            = 0.95;
SIFTopts.matchMinNumInliers  = 10;
SIFTopts.matchMinInlierRatio = 0.0;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get the list of zvalues and section ids within the z range between nfirst and nlast (inclusive)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/sectionData', ...
    rcsource.baseURL, rcsource.owner, rcsource.project, rcsource.stack);
j = webread(urlChar);
sectionId = {j(:).sectionId};
z         = [j(:).z];
indx = find(z>=nfirst & z<=nlast);

sectionId = sectionId(indx);% determine the sectionId list we will work with
z         = z(indx);        % determine the zvalues (this is also the spatial order)
[z, ia] = sort(z);
sectionId = sectionId(ia);
%% [1] generate montage for individual sections and generate montage collection
L = Msection;
L(numel(z)) = Msection;
for lix = 1:numel(z)
    L(lix)                  = Msection(rcsource, z(lix));  % tiles will have stage translations and when requested provide LC images.
    L(lix).dthresh_factor   = 3;
    L(lix)                  = update_XY(L(lix));
    L(lix)                  = update_adjacency(L(lix));
    [L(lix), js]            = alignTEM_inlayer(L(lix));
    L(lix).sectionID        = sectionId(lix);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ingest js into point matches database
    %%% this needs to be done using webwrite --- sosi ---  until then <sigh> we will use curl
    fn = ['temp_' num2str(randi(100000)) '_' num2str(lix) '.json'];
    fid = fopen(fn, 'w');
    fwrite(fid,js);
    fclose(fid);
    urlChar = sprintf('%s/owner/%s/matchCollection/%s/matches/', ...
        pm.server, pm.owner, pm.match_collection);
    cmd = sprintf('curl -X PUT --connect-timeout 30 --header "Content-Type: application/json" --header "Accept: application/json" -d "@%s" "%s"',...
        fn, urlChar);
    [a, resp]= evalc('system(cmd)');
    %disp(a);    disp(resp);
    delete(fn);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
mL = concatenate_tiles(L, opts.outlier_lambda);

ingest_section_into_renderer_database_overwrite(mL, rctarget_montage, rcsource, pwd);
mL = update_tile_sources(mL, rctarget_montage);
L_montage = split_z(mL);

%% [2] generate montage-scapes and montage-scape point-matches

[L2] = generate_montage_scapes_SIFT_point_matches(ms);

% %% filter point matches using RANSAC
geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
geoTransformEst.Method = 'Random Sample Consensus (RANSAC)';%'Least Median of Squares';
geoTransformEst.Transform = 'Affine';%'Nonreflective similarity';%'Affine';%
geoTransformEst.NumRandomSamplingsMethod = 'Desired confidence';
geoTransformEst.MaximumRandomSamples = 1000;
geoTransformEst.DesiredConfidence = 99.95;
for pmix = 1:size(L2.pm.M,1)
    m1 = L2.pm.M{pmix,1};
    m2 = L2.pm.M{pmix,2};
    % Invoke the step() method on the geoTransformEst object to compute the
    % transformation from the |distorted| to the |original| image. You
    % may see varying results of the transformation matrix computation because
    % of the random sampling employed by RANSAC.
    [tform_matrix, inlierIdx] = step(geoTransformEst, m2, m1);
    m1 = m1(inlierIdx,:);
    m2 = m2(inlierIdx,:);
    L2.pm.M{pmix,1} = m1;
    L2.pm.M{pmix,2} = m2;
    w = L2.pm.W{pmix};
    L2.pm.W{pmix} = w(inlierIdx);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % check point match quality
% for lix = 1%:size(L2.pm.adj,1)
%     ix1 = L2.pm.adj(lix,1);
%     ix2 = L2.pm.adj(lix,2);
%     t1 = L2.tiles(ix1);
%     t2 = L2.tiles(ix2);
%     M = L2.pm.M(lix,:);
%     show_feature_point_correspondence(t1,t2,M);title([num2str(ix1) '   ' num2str(ix2)]);
%     drawnow;
% end
%% [3] rough alignment solve for montage-scapes

% solve
[mLR, errR, mLS] = get_rigid_approximation(L2);  % generate rigid approximation to use as regularizer
[mL3, errA] = solve_affine_explicit_region(mLR); % obtain an affine solution
mL3s = split_z(mL3);
%% [4] apply rough alignment to montaged sections (L_montage) and generate "rough_aligned" collection  %% %%%%%% sosi
for lix = 1:numel(L_montage), L_montage(lix) = get_bounding_box(L_montage(lix));end
mL3 = get_bounding_box(mL3);
Wbox = [mL3.box(1) mL3.box(3) mL3.box(2)-mL3.box(1) mL3.box(4)-mL3.box(3)];disp(Wbox);
wb1 = Wbox(1);
wb2 = Wbox(2);
L3 = L_montage;
fac = str2double(ms.scale); %0.25;

smx = [fac 0 0; 0 fac 0; 0 0 1]; %scale matrix
invsmx = [1/fac 0 0; 0 1/fac 0; 0 0 1];
tmx2 = [1 0 0; 0 1 0; -wb1 -wb2 1]; % translation matrix for montage_scape stack

for lix = 1:numel(L_montage)
    b1 = L_montage(1).box;
    dx = b1(1);dy = b1(3);
    tmx1 = [1 0 0; 0 1 0; -dx -dy 1];  % translation matrix for section box
    for tix = 1:numel(L3(lix).tiles)
        newT = L3(lix).tiles(tix).tform.T * tmx1 * smx * mL3s(lix).tiles(1).tform.T * tmx2 * (invsmx);
        L3(lix).tiles(tix).tform.T = newT;
    end
    L3(lix) = update_XY(L3(lix));
end
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
mL = concatenate_tiles(L3, opts.outlier_lambda);
ingest_section_into_renderer_database_overwrite(mL,rctarget_rough, rcsource, pwd);
mL = update_tile_sources(mL, rctarget_rough);
L_rough = split_z(mL);
for lix = 1:numel(L_rough), L_rough(lix) = update_XY(L_rough(lix));end
%% [5] Determine list of section pairs that will be compared
% first determine the list of section pairs
top = numel(L_rough);
bottom = 1;
cs = [];  % compare section list
counter = 1;
for uix = top:-1:bottom
    lowest = uix-depth;
    if lowest<bottom, lowest = bottom;end
    for vix = uix:-1:lowest
        if vix<uix
            cs(counter,:) = [uix vix]+nfirst-1;
            counter = counter + 1;
        end
    end
end
disp(cs);
%% [6] Determine blocks to match

dir_temp_render = L_rough(1).tiles(1).dir_temp_render;
Wbox = zeros(numel(L_rough), 4);
bbox = zeros(numel(L_rough),4);
parfor lix = 1:numel(L_rough)
    [ Wbox(lix,:), bbox(lix,:)] = get_section_bounds_renderer(rctarget_rough, z(lix));
end
% sosi---- im = get_image_box_renderer(rc, t.z, Wbox, 0.1, dir_temp_render, 'rough_block'); imshow(im);
bb = [min(Wbox(:,1)) min(Wbox(2)) max(bbox(:,3)) max(bbox(:,4))];
wb = [bb(1) bb(2) bb(3)-bb(1) bb(4)-bb(2)];

% draw rectangles

%rectangle('Position', wb, 'FaceColor', [0.5 0.5 0.5]);
dx = round(wb(3)/DX);
dy = round(wb(4)/DY);

wbox = zeros(DX*DY, 4);
counter = 1;
for xix = 0:DX-1
    for yix = 0:DY-1
        xpos = bb(1)+xix*dx;
        ypos = bb(2)+yix*dy;
        wbox(counter,:) = [ xpos  ypos dx dy];
        counter = counter + 1;
        %rcolor = rand(1,3);rectangle('Position', wbox, 'FaceColor', rcolor);  pause(1);
    end
end

% list sections and block windows in preparation for parfor
b = zeros(DX*DY,6);
count = 1;
for cix = 1:size(cs,1)    % loop over section pairs
    for bix = 1:size(wbox,1)  % loop over blocks
        b(count,:) = [cs(cix,:) wbox(bix,:)];
        count = count + 1;
    end
end

% get montage boxes as well
Wboxm = zeros(numel(L_montage), 4);
bboxm = zeros(numel(L_montage),4);
parfor llix = 1:numel(L_montage)
    [ Wboxm(llix,:), bboxm(llix,:)] = get_section_bounds_renderer(rctarget_montage, z(llix));
end
bbm = [min(Wboxm(:,1)) min(Wboxm(2)) max(bboxm(:,3)) max(bboxm(:,4))];
wbm = [bbm(1) bbm(2) bbm(3)-bbm(1) bbm(4)-bbm(2)];

%% [7] generate point-matches for all blocks
err_logs = {};
IDS    = {};
PAIRS  = {};
MPAIRS = {};
W      = {};
urls = cell(size(b,1),1);
npms = [];
%parfor_progress(size(b,1));
parfor bix = 1:size(b,1)   % process each line in b (a section pair and block window -- x y W H)
    %disp(['Processing ' num2str(bix) ' of ' num2str(size(b,1))]);
    ids = {};
    pairs = [];
    w = [];
    count = 1;
    %disp(bix);
    box = b(bix, 3:6);
    
    %%% sosi --- check whether this is box is empty for any of the two layers before
    %%% proceeding
    
    %%% generate URLs for the boxes
    url1 = sprintf('%s/owner/%s/project/%s/stack/%s/z/%s/box/%.0f,%.0f,%.0f,%.0f,%s/render-parameters?filter=true',...
        rctarget_rough.baseURL, rctarget_rough.owner, rctarget_rough.project, rctarget_rough.stack, num2str(b(bix,1)), ...
        box(1), ...
        box(2), ...
        box(3), ...
        box(4), ...
        num2str(scale));
    url2 = sprintf('%s/owner/%s/project/%s/stack/%s/z/%s/box/%.0f,%.0f,%.0f,%.0f,%s/render-parameters?filter=true',...
        rctarget_rough.baseURL, rctarget_rough.owner, rctarget_rough.project, rctarget_rough.stack, num2str(b(bix,2)), ...
        box(1), ...
        box(2), ...
        box(3), ...
        box(4), ...
        num2str(scale));
    urls{bix} = {url1, url2};
    [m_2, m_1, ~, err_logs{bix}] = point_match_gen_SIFT_qsub(url2, url1, SIFTopts);   % submits jobs -- returns point-matches in box coordinate system%%% production --- submit to cluster
    MPAIRS{bix} = [m_1 m_2];
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%% sosi test best siftopts
%     SIFTopts.SIFTfdSize        = 8;
%     SIFTopts.SIFTmaxScale      = 1.0;
%     SIFTopts.SIFTminScale      = 0.2;
%     SIFTopts.SIFTsteps         = 8;
%     
%     SIFTopts.matchMaxEpsilon     = 40;
%     SIFTopts.matchRod            = 0.95;
%     SIFTopts.matchMinNumInliers  = 10;
%     SIFTopts.matchMinInlierRatio = 0.0;
% 	clear sift_opts npoints
%     counter = 1;
%     M_1 = {};
%     M_2 = {};
%     for fd_size = 10 : -2.0: 4
%         for max_scale = 0.6 : 0.1: 0.9 
%             for min_scale = 0.4 :0.1: 0.5
%                 for steps = 4 : 2 : 8
%                     for match_max_epsilon = 15:5:25
%                         for match_rod = 0.85 : 0.05 : 0.97
%                             for match_min_numinliers = 10:5:20
%                                 for match_min_inlier_ratio = 0.0
%                                     
%                                     
%                                     SIFTopts.SIFTfdSize        = fd_size;
%                                     SIFTopts.SIFTmaxScale      = max_scale;
%                                     SIFTopts.SIFTminScale      = min_scale;
%                                     SIFTopts.SIFTsteps         = steps;
%                                     
%                                     SIFTopts.matchMaxEpsilon     = match_max_epsilon;
%                                     SIFTopts.matchRod            = match_rod;
%                                     SIFTopts.matchMinNumInliers  = match_min_numinliers;
%                                     SIFTopts.matchMinInlierRatio = match_min_inlier_ratio;
%                                     
%                                     sift_opts(counter) = SIFTopts;
%                                     counter = counter + 1;
%                                     m_1 = [];
%                                     m_2 = [];
%                                     disp('-------------------------------');
%                                     disp(SIFTopts);
% %                                      disp(counter);
%                                     disp('-------------------------------');
%                                     try
%                                     [m_2, m_1, ~, err_logs{bix}] = point_match_gen_SIFT_qsub(url2, url1, SIFTopts);   % submits jobs -- returns point-matches in box coordinate system%%% production --- submit to cluster
%                                     catch
%                                         disp('Skipping');
%                                     end
%                                     M_1{counter} = m_1;
%                                     M_2{counter} = m_2;
%                                     disp('Result:');
%                                     disp(size(m_1));
%                                     npoints(counter) = size(m_1,1);
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end
%         end
%     end
        
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%% SOSI == look at images and point matches
%     disp(err_logs{bix});
%     [im1, v1] = get_image_box_renderer(rctarget_rough, b(bix,1), box, scale, num2str(b(bix,1)));
%     [im2, v2] = get_image_box_renderer(rctarget_rough, b(bix,2), box, scale, num2str(b(bix,2)));
%      figure; showMatchedFeatures(im1, im2, m_1, m_2, 'montage');
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    npms(bix) = size(m_2,1);
    if ~isempty(m_1),
        try
            % convert these point-matches to "acquire or montage" coordinate system to make them ingestable json strings that will go into pm collection
            z1 = b(bix,1);
            z2 = b(bix,2);
            for pimix = 1:size(m_1,1)   % loop over box point-matches
                % Strategy: for each set of point we convert from (rough-aligned) world to (raw) local
                % What we really want is local "acquire" (i.e. without the last transformation, but after LC),
                % so we (a) convert from (raw) local to acquire world (where we know the last transformation is only translation), then
                % (b) subtract translation component of tile specs from points so that they become (acquire) local
                % The logic to do this is in 'world_to_local_LC_tile.m'
                
                %%%%%%%%%%%
                % first convert point found in the first box (in layer(b(bix,1)))
                %%%%%%%%%%%%
                x = m_1(pimix, 1)/scale + box(1);
                y = m_1(pimix, 2)/scale + box(2);
                
                [pGroupId, p] = world_to_local_LC_tile(rctarget_rough, rctarget_montage, [x y z1], wbm);
                if ~isempty(pGroupId)
                    %%%%%%%%%%%
                    % second convert point found in the second box (in layer(b(bix,2)))
                    %%%%%%%%%%%%
                    x = m_2(pimix, 1)/scale + box(1);
                    y = m_2(pimix, 2)/scale + box(2);
                    
                    [qGroupId, q] = world_to_local_LC_tile(rctarget_rough, rctarget_montage, [x y z2], wbm);
                    
                    % write into buffer
                    if ~isempty(pGroupId) && ~isempty(qGroupId) && ~isempty(p) && ~isempty(q)
                        ids{count,1} = pGroupId;
                        ids{count,2} = qGroupId;
                        pairs(count,:) = [p q];
                        w(count) =1/(1 + abs(z1-z2));
                    end
                end
                count = count + 1;
            end
%                     %%% SOSI == look at images and point matches
%                     [im1, v1] = get_image_box_renderer(rctarget_rough, b(bix,1), box, scale, dir_temp_render, num2str(b(bix,1)));
%                     [im2, v2] = get_image_box_renderer(rctarget_rough, b(bix,2), box, scale, dir_temp_render, num2str(b(bix,2)));
%                      clf;warning off;imshowpair(im1, im2, 'montage'); title(num2str(bix));drawnow
            
            %         figure; warning off;showMatchedFeatures(im1, im2, m_1, m_2, 'montage');
                    %%% sosi == look at point matches in pairs and confirm correspondence to original feature matches
%                     pix = 3;
%                     tid1 = L_montage(z1-nfirst+1).map_renderer_id(ids{pix,1});
%                     tid2 = L_montage(z2-nfirst+1).map_renderer_id(ids{pix,2});
%                     t1 = L_montage(z1-nfirst+1).tiles(tid1);
%                     t2 = L_montage(z2-nfirst+1).tiles(tid2);
%                     imt1 = get_image(t1);figure;imshow(imt1);hold on;plot(pairs(pix,1), pairs(pix,2),'*y');
%                     imt2 = get_image(t2);figure;imshow(imt2);hold on;plot(pairs(pix,3), pairs(pix,4),'*w');
                    
        catch err_world_to_local_tile
            kk_disp_err(err_world_to_local_tile);
        end
    end
    IDS{bix}    = ids;
    PAIRS{bix}  = pairs;
    W{bix}      = w;
    %parfor_progress;
end
%parfor_progress(0);
% prepare point-match data for ingestion
% delete empty entries into IDS and PAIRS
del_ix = zeros(size(b,1),1, 'logical');
for bix = 1:size(b,1)
    if isempty(IDS{bix}), del_ix(bix) = 1;end
end
disp('----------------------------');
disp(['Number of empty blocks: ' num2str(sum(del_ix))]);
disp('----------------------------');

IDS(del_ix) = [];
PAIRS(del_ix) = [];
b(del_ix,:) = [];
npms(del_ix) = [];

MPAIRS(del_ix) = [];
urls(del_ix) = [];
red_err_logs = err_logs;
red_err_logs(del_ix) = [];

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%% sosi -------------- to check on quality of point matches found
% for ix = 1:size(b,1)
%     disp(red_err_logs{ix});
%     disp(IDS{ix});
%     m_1 = MPAIRS{ix}(:,1:2);
%     m_2 = MPAIRS{ix}(:,3:4);
%     box = b(ix, 3:6);
%     [im1, v1] = get_image_box_renderer(rctarget_rough, b(ix,1), box, scale, num2str(b(ix,1)));
%     [im2, v2] = get_image_box_renderer(rctarget_rough, b(ix,2), box, scale, num2str(b(ix,2)));
%     figure(1);clf; showMatchedFeatures(im1, im2, m_1, m_2, 'montage'); drawnow;
%     pause(2);
%     
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% concatenate data (this is a chore to be done after parfor --- consider outsourcing to some method)
% we want to make lists of tile-ids and corresponding point matches in LC frame
rids = {};
pms  = [];
sids = {};
zs = [];
for ix = 1:numel(IDS)
    rids = [rids;IDS{ix}];
    pms  = [pms; PAIRS{ix}];
    zs   = [zs; [ones(size(PAIRS{ix},1),1)*b(ix,1) ones(size(PAIRS{ix},1),1)*b(ix,2)]];
    %     sids{ix,1} = sectionId{b(ix,1)};
    %     sids{ix,2} = sectionId{b(ix,2)};
end
cids = {};
for ix = 1:size(rids,1)
    cids{ix} = [rids{ix,1} '__' rids{ix,2}];
end
[C ia, ic] = unique(cids);
n_pairs = size(ia,1);


% sosi --- svae intermediate state
pd = pwd;td = '/groups/flyTEM/home/khairyk/mwork/temp' ;cd(td);save intermediate_stage_7_finished;cd(pd);

% at this point we have a list of unique cids (combined renderer ids)
% for a specific cid, to find its occurrences (linear index) in rids and pms we need to do for example:
% [c] = ismember(cids, C{1})
%% [8] generate json and ingest into pm database
for mix = 1:n_pairs    % loop over point matches
    [c] = find(ismember(cids, C{mix}));             % get linear index into rids, pms
    sectionID1 = sectionId{zs(c(1),1)-nfirst+1};
    sectionID2 = sectionId{zs(c(1),2)-nfirst+1};
    tid1 = rids{c(1),1};
    tid2 = rids{c(1),2};
    
    MP{mix}.pz = sectionID1;
    MP{mix}.pId= tid1;
    MP{mix}.p  = pms(c,[1 2]);
   
    
    MP{mix}.qz = sectionID2;
    MP{mix}.qId= tid2;
    MP{mix}.q  = pms(c,[3 4]);
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%% sosi -- look at this tile pair and point-matches
%     disp(sectionID1);
%     disp(sectionID2);
%     disp(tid1);
%     disp(tid2);
%     z2 = zs(c(1),1)-nfirst+1;
%     z1 = zs(c(1),2)-nfirst+1;
%     
%     tix1 = L_montage(z2).map_renderer_id(tid1);
%     tix2 = L_montage(z1).map_renderer_id(tid2);
%     
%     t1 = L_montage(z2).tiles(tix1); 
%     t2 = L_montage(z1).tiles(tix2);
%     im1 = get_image(t1);
%     im2 = get_image(t2);
%     
%     m_1 = MP{mix}.p;
%     m_2 = MP{mix}.q;
%      figure(1);clf; showMatchedFeatures(im1, im2, m_1, m_2, 'montage'); drawnow;
%     
%     pause(3);
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
js = pairs2json(MP); % generate json blob to be ingested into point-match database


%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ingest js into point matches database
%%% this needs to be done using webwrite --- sosi ---  until then <sigh> we will use curl
fn = ['temp_' num2str(randi(100000)) '_' num2str(lix) '.json'];
fid = fopen(fn, 'w');
fwrite(fid,js);
fclose(fid);
urlChar = sprintf('%s/owner/%s/matchCollection/%s/matches/', ...
    pm.server, pm.owner, pm.match_collection);
cmd = sprintf('curl -X PUT --connect-timeout 30 --header "Content-Type: application/json" --header "Accept: application/json" -d "@%s" "%s"',...
    fn, urlChar);
[a, resp]= evalc('system(cmd)');
delete(fn);
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% [9] Solve system and ingest into Renderer database

opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 1e0;
opts.edge_lambda = 1e1;
opts.solver = 'backslash';
opts.min_points = 10;
opts.nbrs = depth;
opts.xs_weight = 0.1;
opts.stvec_flag = 1;  % i.e. use the provided collection trasformations as starting values
[mL, A]= solve_slab(rctarget_rough, pm, nfirst, nlast, rctarget_align, opts);
T = array2table(A{1});
disp(T);
kk_clock;

%% solve again with degree 2 and put in another collection
% configure align collection
rctarget_align.stack          = ['EXP_v12_alignP2_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 2;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 1e2;
opts.edge_lambda = 1e4;
opts.solver = 'backslash';
opts.min_points = 10;
opts.nbrs = depth;
opts.xs_weight = 0.1;
opts.stvec_flag = 1;  % i.e. use the provided collection trasformations as starting values
[mL, A]= solve_slab(rctarget_rough, pm, nfirst, nlast, rctarget_align, opts);
T = array2table(A{1});
disp(T);
kk_clock;








































