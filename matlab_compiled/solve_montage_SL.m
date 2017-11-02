function [mL] = solve_montage_SL(argin)
% Intended for deployment: solve matrix system based on json input provided by fn


if isstruct(argin)
    sl = argin;
else
    fn = argin;
    disp(['-------  Using input file: ' fn]);
    % read json input
    sl = loadjson(fileread(fn));
end



if iscell(sl.source_point_match_collection) %Then contains multiple pms
    for i =1:numel(sl.source_point_match_collection)
        temp_source_point_match_collection(i) = sl.source_point_match_collection{i};
    end
    sl.source_point_match_collection = temp_source_point_match_collection;
end

%%% let's make sure this script doesn't fail because of missing petty parameters
if ~isfield(sl, 'verbose')
    sl.verbose = 0;
end



if sl.verbose
    kk_clock();

    disp(['Section(s) with z value:' num2str(sl.z_value)]);
    disp('Using solver options:');disp(sl.solver_options);
    disp('Using source collection:');disp(sl.source_collection);
    disp('Using target collection:');disp(sl.target_collection);
    for i = 1:numel(sl.source_point_match_collection)
        disp('Using point-match collection:');disp(sl.source_point_match_collection(i));
    end
end
%% overrides and checks
sl.section_number = sl.z_value; % same thing but messed up variable names later

if ~isfield(sl, 'disableValidation'), sl.disableValidation = 1;end
if ~isfield(sl.target_collection, 'initialize'), sl.target_collection.initialize = 0;end

if ~isfield(sl.target_collection, 'complete'), sl.target_collection.complete = 0;end
if ~isfield(sl.solver_options, 'da'), sl.solver_options.da = 0.05;end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rctarget = sl.target_collection;
rcsource = sl.source_collection;

%% load point matches and solve
if sl.solver_options.use_peg
    if sl.verbose, disp('Solving montage using pegs');end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%---LOAD POINT-MATCHES---%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     tic;if sl.verbose, disp('-- Loading point matches');end
    %     [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
    %         load_point_matches(sl.section_number,sl.section_number, sl.source_collection, ...
    %         sl.source_point_match_collection, 0, sl.solver_options.min_points, 0, sl.solver_options.max_points); %
    %     toc


    %%%% load all available point-matches for this section
    [zu, sID, sectionId, z, ns] = get_section_ids(rcsource,...
        sl.section_number, sl.section_number);
    [T, map_id, tIds, z_val, r, c] = load_all_transformations(rcsource,...
        zu, sl.dir_scratch);

    [M, adj, W, np] = system_solve_helper_load_point_matches(...
        zu, sl.solver_options, sl.source_point_match_collection, map_id, ...
        sID, size(T,1), r, c);
    %[x1, y1, tids] = get_tile_centers(rcsource, zu, 0);
    %%% generate a subset of tiles that have point-matches
    t_ix = unique(adj); % valid tiles are only the ones connected by point-matches
    ntiles = numel(t_ix);
    disp('----- Removing number of orphan tiles based on point-matches ----');
    disp(size(T,1)-ntiles);
    disp('------------------------------------------');
    tiles = tile;tiles(ntiles) = tile; % start a tile array
    a = [];
    for tix = 1:ntiles    %%%% construct a tile array based on valid tiles
        t = T(t_ix(tix),:);
        tiles(tix) = tile(z_val(t_ix(tix)), tix,...
            t(1), t(2), t(3), t(4), t(5), t(6),...
            -999, -999, -999, '', -999, -999, tIds{t_ix(tix)});
        counter_id{tix} = {tix};
        tiles(tix).id = tix;
        id_vec{tix} = tiles(tix).renderer_id;
        tiles(tix).server = rcsource.baseURL;
        tiles(tix).owner = rcsource.owner;
        tiles(tix).project = rcsource.project;
        tiles(tix).stack = rcsource.stack;
    end
    map_id_new = containers.Map(id_vec, counter_id);  %%% map renderer ids to indices of valid array

    %%% generate correct indexing: map old indices to new indices using renderer_id
    for aix = 1:size(adj,1)
        rid_old1 = map_id_new(tIds{adj(aix,1)}); % get index of same renderer_id but in new set
        rid_old2 = map_id_new(tIds{adj(aix,2)});
        a(aix,:) = [rid_old1{1} rid_old2{1}];
    end
    adj = a;

%     %%%% assert uniqueness of adj or delete duplicates (issue warning)
%     [c, ai, bi] = unique(adj,'rows');
%     u = setxor(ai, [1:size(adj,1)]);
%     if ~isempty(u)
%         warning('Removing duplicate tile-pair point-match sets -- consider merging point-matches in future');
%         disp(['Total removed: ' num2str(numel(u))]);
%     end
%     adj(u,:) = [];
%     M(u,:)  = [];
%     W(u) = [];
%     np(u) = [];


    PM.M = M;
    PM.adj = adj;
    PM.W = W;
    PM.np = np;
    L = Msection(tiles);
    L.pm = PM;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%      sosi: analyze quality of point-matches
    %%% --- needs to go into filter_pm_local in system_solve_helper_load_point_matches
    res = zeros(size(L.pm.M,1), 2);
    delix = [];
    filter_by_bounds = 0;  % under testing: is this necessary and when to turn on -- necessary for section 37 FAFB
%     try
    L.tiles(1) = L.tiles(1).set_info;
    W = L.tiles(1).W;
    H = L.tiles(1).H;
%     catch error_tile_info
%         kk_disp_err(error_tile_info);
%         filter_by_bounds = 0;
%     end


    f = 3.5;  % larger values mean narrower permissive region
    for pix = 1:size(L.pm.M,1)
        m1 = L.pm.M{pix,1};
        m2 = L.pm.M{pix,2};
        dx = [m1(:,1)-m2(:,1)];
        dy = [m1(:,2)-m2(:,2)];
        res(pix,:) = [std(dx) std(dy)];  % std should be small for high quality point-match sets

        if filter_by_bounds
            % further filter point-match sets that are obviously out of acceptable bounds
            % [1] point-matches are not allowed within a central rectangle: ratio f of the dimension
            if any( m1(:,1)<(W-W/f) & m1(:,1)>(W/f) & m1(:,2)<(H-H/f) & m1(:,2)>(H/f))
                delix = [delix; pix];
                %disp(['Deleting pair: ' num2str(pix) ' Point-match set self-consistent, but outside bounds.']);
            end
            disp(['Section: ' num2str(L.z) ' -- Removing ' num2str(numel(delix)) ' point-match sets outside bounds']);

        end
    end


    thresh = 8;%0.9;
    disp(max(res));
    disp(find(res(:,1)==max(res(:,1))));
    disp(find(res(:,2)==max(res(:,2))));
    delix = [delix; find(res(:,2)>thresh)];
    delix = [delix; find(res(:,1)>thresh)];
    delix = unique(delix(:));
    disp(['Total current point-match sets: ' num2str(size(L.pm.M,1))]);
    disp(['deleting ' num2str(numel(delix)) ' point-match sets: '])
    disp(delix);
    %
    %     figure; hist(res(:,1), 30);title('histogram of standard deviations for point-matches -- x');
    %     figure; hist(res(:,2), 30);title('histogram of standard deviations for point-matches -- y');
    %     drawnow;

    L.pm.M(delix,:) = [];
    L.pm.adj(delix,:) = [];
    L.pm.W(delix) = [];
    L.pm.np(delix) = [];


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tic;if sl.verbose, disp('-- Adding pegs');end
    L = add_translation_peggs(L, sl.solver_options.peg_npoints, sl.solver_options.peg_weight, 'all');
    toc
    tic;if sl.verbose, disp('-- Asserting one connected component');end
    [L, ntiles] = reduce_to_connected_components(L);
    L = L(1);
    toc
    tic;if sl.verbose, disp('-- Solving for rigid approximation');end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    sl.solver_options.distributed = 0;
    [Lr, errR, mL, is, it, Res]  = get_rigid_approximation(L, sl.solver_options.solver, sl.solver_options);
    toc
    tic;if sl.verbose, disp('-- Removing pegs');end

    %%% remove peggs and last tile
    last_tile = numel(Lr.tiles);
    del_ix = find(Lr.pm.adj(:,2)==last_tile);
    Lr.pm.M(del_ix,:)  = [];
    Lr.pm.adj(del_ix,:) = [];
    Lr.pm.W(del_ix) = [];
    Lr.pm.np(del_ix) = [];
    Lr.tiles(end) = [];
    Lr = update_adjacency(Lr);
    toc


    if sl.solver_options.degree == 1
        tic;
        if sl.verbose, disp('-- Solving for affine');end

        [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
            invalid] = solve_affine_explicit_region(Lr, sl.solver_options);
        toc
    elseif sl.solver_options.degree>1
        [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
            invalid] = solve_polynomial_explicit_region(Lr, sl.solver_options.degree, sl.solver_options);
    else
        if sl.verbose, disp(' Only performed rigid approximation ' );end
        mL = Lr;
    end

else
    tic;if sl.verbose, disp('Solving slab without pegs --- each connected component by itself');end
    [mL, pm_mx, err, R, ~, ntiles, PM, sectionId_load, z_load] = ...
        solve_slab(sl.source_collection, sl.source_point_match_collection, ...
        sl.section_number, sl.section_number, [], sl.solver_options);
    toc

end

%%% filter the tile set using area and perimeter ratio thresholds
[mL, A, S, indx, delIds] = filter_based_on_tile_area_threshold(mL, sl.solver_options.da);
disp(['Removed: ' num2str(numel(indx)) ' outlier tiles']);
%% ingest into Renderer database (optional);

tic;if sl.verbose, disp('-- Ingesting section into collection');end
resp = ingest_section_into_LOADING_collection(mL, rctarget,...
    rcsource, sl.temp_dir, 1, sl.disableValidation); % ingest

if sl.target_collection.complete
    if sl.verbose, disp('Completing collection');end
    resp = set_renderer_stack_state_complete(rctarget);  % set to state COMPLETE
end
if sl.verbose
    disp(resp);
    disp('Finished:');
    kk_clock();
end


%% optional
%str = view_collection_dashboard(sl.target_collection); disp(str);
