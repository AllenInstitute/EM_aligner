% The script assumes the existence of a Renderer collection (configured below)
% Dependencies:
%               - Renderer service
%               - script to generate spark_montage_scapes
%
% Calculate rough alignment of a set of sections
% Ingest this into a new collection
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [0] configure collections and prepare quantities
clc; clear all;
kk_clock;
nfirst = 1;
nlast  = 100;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection

rctarget_montage.stack          = ['EXP_v12_montage_1_7060'];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% configure rough collection
rctarget_rough.stack          = ['EXP_v12_xrough_' num2str(nfirst) '_' num2str(nlast)];
rctarget_rough.owner          ='flyTEM';
rctarget_rough.project        = 'test';
rctarget_rough.service_host   = '10.37.5.60:8080';
rctarget_rough.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rctarget_rough.verbose        = 1;

% configure tile point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'FAFBv12_set_01';

% configure montage-scape generation ( for rough alignment)
ms.service_host                 = rctarget_montage.service_host;
ms.owner                        = rctarget_montage.owner;
ms.project                      = rctarget_montage.project;
ms.stack                        = rctarget_montage.stack;
ms.first                        = num2str(nfirst);
ms.last                         = num2str(nlast);

ms.fd_size                      = '8';
ms.min_sift_scale               = '0.55'; % 0.55
ms.max_sift_scale               = '1.0';
ms.steps                        = '3'; % 3
ms.scale                        = '0.1';    % normally less than 0.05 -- can be large (e.g. 0.2) for very small sections (<100 tiles)
ms.similarity_range             = '10';    % maximum number of layer for similarity comparisons
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nobackup/flyTEM/spark_montage';
ms.run_dir                      = ['scale_' ms.scale];
ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '8';
% configure fine alignment

DX = 5;   % number of divisions of the total bounding box in x
DY = 5;
scale = 0.25;
depth = 3;  % largest distance (in layers) considered for neighbors

SIFTopts.SIFTfdSize        = 8;
SIFTopts.SIFTmaxScale      = 1.0;
SIFTopts.SIFTminScale      = 0.2;
SIFTopts.SIFTsteps         = 8;

SIFTopts.matchMaxEpsilon     = 40;
SIFTopts.matchRod            = 0.95;
SIFTopts.matchMinNumInliers  = 10;
SIFTopts.matchMinInlierRatio = 0.0;



%% [2] generate montage-scapes and montage-scape point-matches

[L2] = generate_montage_scapes_SIFT_point_matches(ms);
L2v = L2;
% %% filter point matches using RANSAC
geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
geoTransformEst.Method = 'Random Sample Consensus (RANSAC)';%'Least Median of Squares';
geoTransformEst.Transform = 'Affine';%'Nonreflective similarity';%'Affine';%
geoTransformEst.NumRandomSamplingsMethod = 'Desired confidence';
geoTransformEst.MaximumRandomSamples = 1000;
geoTransformEst.DesiredConfidence = 99.95;
for pmix = 1:size(L2v.pm.M,1)
    m1 = L2v.pm.M{pmix,1};
    m2 = L2v.pm.M{pmix,2};
    % Invoke the step() method on the geoTransformEst object to compute the
    % transformation from the |distorted| to the |original| image. You
    % may see varying results of the transformation matrix computation because
    % of the random sampling employed by RANSAC.
    [tform_matrix, inlierIdx] = step(geoTransformEst, m2, m1);
    m1 = m1(inlierIdx,:);
    m2 = m2(inlierIdx,:);
    L2v.pm.M{pmix,1} = m1;
    L2v.pm.M{pmix,2} = m2;
    w = L2v.pm.W{pmix};
    L2v.pm.W{pmix} = w(inlierIdx);
    L2v.pm.np(pmix) = numel(w(inlierIdx));
end

% we need to check whether we have one connected component or more 
L2.G = graph(L2.pm.adj(:,1), L2.pm.adj(:,2));
nconn1 = numel(unique(conncomp(L2.G)));

L2v.G = graph(L2v.pm.adj(:,1), L2v.pm.adj(:,2), L2v.pm.np);
nconn2 = numel(unique(conncomp(L2v.G)));
if nconn2~=1, 
    disp(['Number of connected components original: ' num2str(nconn1)]);
    disp(['Number of connected components pruned: ' num2str(nconn2)]);    
    error('One (and only one) connected component is allowed in rough alignment');
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
[mLR, errR, mLS] = get_rigid_approximation(L2v);  % generate rigid approximation to use as regularizer
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
