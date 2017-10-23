function [obj, M, adj] = generate_point_matches(obj, thresh, filter, scale)
% calculates all features for all tiles and generates point matches
% structure, with point locations, adjacency and weights
% SOSI: parallel point-matches generation is needed
% SOSI: does not handle orphan tiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2, thresh = 12;end;
if nargin<3, filter = 'true';end
if nargin<4, scale = 1.0; disp('Using default scale: 1.0');end
if isempty(obj.A),
    warning('No adjacency matrix found, calculating');
    obj = update_XY(obj);
    obj = update_adjacency(obj);
end
if size(obj.A,1)~=numel(obj.tiles)
    warning('Invalid or outdated adjacency matrix, recalculating');
    obj = update_XY(obj);
    obj  = update_adjacency(obj);
end
disp('Neighbor threshold factor used:');
disp(obj.dthresh_factor);
obj  = update_adjacency(obj);
% if isdeployed
%     delete(gcp('nocreate'));
%     disp('Starting parallel pool');
%     
%     
%     parpool(ncluster);
%     poolobj = gcp('nocreate');
%     disp(['Parallel pool created. Pool size: ' num2str(poolobj.NumWorkers)]);
%     
% end

if isdeployed
    disp('Calculating features for all tiles...');
    tic;
end
%for tix = 1:numel(obj.tiles), obj.tiles(tix).fetch_local = 1;end
force = 1;
[obj] = calculate_tile_features(obj, filter, force, scale);

if isdeployed
    toc
    disp('Done!');
end

[r, c] = ind2sub(size(obj.A), find(obj.A));  % neighbors are determined by the adjacency matrix

%% % distributed tile-pair matching
mL2_tiles = obj.tiles;
M = cell(numel(r),2);
adj = zeros(numel(r),2);
W = cell(numel(r),1);
np = zeros(numel(r),1);
delpix = zeros(numel(r),1, 'uint32');
%count = 1;
disp('Calculating point matches using parfor .... ');
tic
%parfor_progress(numel(r));
parfor pix = 1: numel(r)
    %    disp(['Point matching: ' num2str(pix) ' of ' num2str(numel(r))]);
    try
     %disp(['Calculating point-match set: ' num2str(pix) ' of ' num2str(numel(r))]);
    f1 = mL2_tiles(r(pix)).features;
    f2 = mL2_tiles(c(pix)).features;
    vp1 = mL2_tiles(r(pix)).validPoints;
    vp2 = mL2_tiles(c(pix)).validPoints;
    [m1, m2, ~]  = im_pair_match_features(f1, vp1, f2, vp2);
    M(pix,:) = {[m1]/scale,[m2]/scale};
    adj(pix,:) = [r(pix) c(pix)];
    W(pix) = {[ones(size(m1,1),1) * 1/(1+ abs(mL2_tiles(r(pix)).z-mL2_tiles(c(pix)).z))]};
    np(pix)  = size(m1,1);
    %%%% mark for removal point-matches that don't have enough point pairs
    if size(m1,1)<thresh
        delpix(pix) = 1;
    end

    catch err_pmatching
        %kk_disp_err(err_pmatching);
        delpix(pix) = 1;
    end
    %parfor_progress
end
%parfor_progress(0);

toc
disp('Done!');


% if isdeployed
% 
% disp('Deleting parallel pool');
% delete(poolobj);
% end

if isempty(M), error('No matches found');end;
delpix = logical(delpix);
disp(['Total number of tested pairs: ' num2str(numel(r))]);
disp(['Total number of point-match sets: ' num2str(numel(r)-sum(delpix))]);
M(delpix,:) = [];
adj(delpix,:) = [];
W(delpix) = [];
np(delpix) = [];

obj.pm.M = M;
obj.pm.adj = adj;
obj.pm.W = W;
obj.pm.np = np;
































