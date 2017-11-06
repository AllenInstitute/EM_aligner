function [resp] = rigid_insert_section(rcsource, rctarget, pm, zrange, opts)
%% insert a section from collection rcsource, into rctarget (replacing all
%  tiles in rctarget) using rigid transformation for the whole section (not individual tiles)
% if z is only one section number, then z-1 and z+1 in rctarget will be used
% for estimating the rotation/translation needed, else z should specify
% with section to use. For example: z = [ 3 4 5], means fitting will be done
% using sections 3 and 5 from rctarget, and section 4 from rcsource.
% Section 4 in this case will be transformed (rigid) and ingested into rctarget.
% the new section 4 will replace any tiles in rctarget that had z = 4.
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


disp('WARNING: UNDER TESTING ---- DOES NOT PRODUCE CORRECT RESULTS');

if numel(zrange)==1
    zrange = [zrange-1:zrange+1];
end
%% Create a temporary working collection with the three relevant sections
% two from target, sandwiching the section from source
rctemp.stack          = ['temp_work_' num2str(zrange(1)) '_' num2str(zrange(end))];
rctemp.owner          = rctarget.owner;
rctemp.project        = rctarget.project;
rctemp.service_host   = rctarget.service_host;
rctemp.baseURL        = rctarget.baseURL;
rctemp.verbose        = 0;
create_renderer_stack(rctemp);

% copy sections
copy_renderer_section([zrange(1) zrange(3)], rctarget, rctemp, opts.dir_scratch);
copy_renderer_section(zrange(2), rcsource, rctemp, opts.dir_scratch);
set_renderer_stack_state_complete(rctemp);

%% load point-matches
[zu, sID, sectionId, z, ns] = get_section_ids(rctemp,zrange(1), zrange(3));
[T, map_id, tIds, z_val] = load_all_transformations(rctemp, zrange, opts.dir_scratch);
[M, adj, W, np, discard] = system_solve_helper_load_point_matches(...
    z, opts, pm, map_id, sID, size(T,1));


%% map points to world to generate X1 Y1 X2 Y2
X1 = [];
Y1 = [];
X2 = [];
Y2 = [];
for pix = 1:size(adj,1)  % loop over point match sets
    
    zv1 = z_val(adj(pix,1));
    zv2 = z_val(adj(pix,2));

    
    if zv1==zrange(2) && (zv1~=zv2)
        % if the point-set in the first column of M
        % corresponds to the sandwich section, but we are not looking at
        % montage point-matches
        
        m1 = M{pix,1};
        m2 = M{pix,2};
        tileId1 = tIds(adj(pix,1));
        tileId2 = tIds(adj(pix,2));
        
    elseif z_val(adj(pix,2))==zrange(2) && (z_val(adj(pix,1))~=z_val(adj(pix,2)))
        % if the point-set in the second column of M
        % corresponds to the sandwich section, but we are not looking at
        % montage point-matches
        m1 = M{pix,2};
        m2 = M{pix,1};
        tileId1 = tIds(adj(pix,2));
        tileId2 = tIds(adj(pix,1));
    end

    
    if zv1==zrange(2) || zv2==zrange(2)
        % i.e. if adjacency is between tiles not involving the sandwich
        %%% do the actual mapping from local coordinates to rctarget world    

        [x1, y1, err] = local_to_world(rctemp, tileId1, m1(:,1), m1(:,2));
        if err==0
            X1 = [X1;x1];
            Y1 = [Y1;y1];
        end
        if err==0
            [x2, y2, err] = local_to_world(rctemp, tileId2, m2(:,1), m2(:,2));
            X2 = [X2;x2];
            Y2 = [Y2;y2];
        end
    end
    
end

if isempty(X1), error('No point-matches found ?');end
disp('Done!');


%% find rotation/translation to overlap tiles
A = [X1 Y1];
B = [X2 Y2];

assert(size(A,1)==size(B,1));
centroid_A = mean(A);
centroid_B = mean(B);
% disp('-- Building linear system for rotation');
N = size(A,1);
H = (A-repmat(centroid_A,N,1))' * (B-repmat(centroid_B,N,1));
[U,S,V] = svd(H);
R = V*U';
if det(R)<0  % detect reflection special case
    V(:,1) = V(:,1) * (-1);
    R = V*U';
end
%disp('-- building linear system for translation');
U = [X1 Y1];% + repmat(t(:)', length(X1),1);
V = [X2 Y2] *R;
warning off; x = ones(length(X1),2)\(V-U);warning on;
V = V - repmat(x(1,:), length(X1),1);
T2 = zeros(3,3);
T2(3,3) = 1;
T2([3 6]) = x(1,:);
% % assemble full trnsformation matrix rotation and translation
Tr = zeros(3,3);Tr(3,3) = 1;
Tr(1:2,1:2) = R;
T3 = T2;
T = T3  + Tr;
T(3,3) = 1;

T = inv(T);
T([7 8]) = 0;
%% read in tiles of the sandwich section

[~, tiles] = get_slab_tiles(rctemp, zrange(2), zrange(2));


%% transform sandwich section

disp('Applying transformations to moving tiles...');
% initialize transformed tile arrays
tilest = tiles;

% apply transformation to all tiles
for tix = 1:numel(tiles)
    t = tiles(tix).tform.T *T;
    t([7 8 9]) = [0 0 1];
    tilest(tix).tform.T = t;
end
L = Msection(tilest);

%% export to collection
delete_renderer_section(rctemp, zrange(2));% optionally delete the section from destination before ingesting
ingest_section_into_renderer_database(L, rctemp, rcsource, opts.dir_scratch, 0, 0, 0);

%% Complete the stack
disp('Complete stack')
resp = set_renderer_stack_state_complete(rctemp);







































