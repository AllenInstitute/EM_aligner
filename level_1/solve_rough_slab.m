function [L2, needs_correction, pmfn, zsetd, zrange, t,dir_spark_work, cmd_str, fn_ids, ...
    target_solver_path, target_ids, target_matches, target_layer_images] = ...
    ...
    solve_rough_slab(dir_store_rough_slab, rcsource, rctarget_montage, ...
    rctarget_rough,ms, nfirst, nlast, dir_rough_intermediate_store, ...
    run_now, precalc_ids, precalc_matches, precalc_path, solve_first, solve_last, solve_name)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [0] configure collections and prepare quantities
% clc; clear all;
% kk_clock;
% nfirst = 1;
% nlast  = 15;
%
% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
%
% % configure montage collection
% rctarget_montage.stack          = ['EXP_dmesh_montage_P1'];
% rctarget_montage.owner          ='flyTEM';
% rctarget_montage.project        = 'test';
% rctarget_montage.service_host   = '10.37.5.60:8080';
% rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
% rctarget_montage.verbose        = 1;
%
%
% % configure rough collection
% rctarget_rough.stack          = ['EXP_dmesh_rough_P1_' num2str(nfirst) '_' num2str(nlast)];
% rctarget_rough.owner          ='flyTEM';
% rctarget_rough.project        = 'test';
% rctarget_rough.service_host   = '10.37.5.60:8080';
% rctarget_rough.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
% rctarget_rough.verbose        = 1;
%
%
% % configure montage-scape point-match generation
% ms.service_host                 = rctarget_montage.service_host;
% ms.owner                        = rctarget_montage.owner;
% ms.project                      = rctarget_montage.project;
% ms.stack                        = rctarget_montage.stack;
% ms.first                        = num2str(nfirst);
% ms.last                         = num2str(nlast);
% ms.fd_size                      = '8';
% ms.min_sift_scale               = '0.55';
% ms.max_sift_scale               = '1.0';
% ms.steps                        = '3';
% ms.scale                        = '0.1';    % normally less than 0.05 -- can be large (e.g. 0.2) for very small sections (<100 tiles)
% ms.similarity_range             = '15';
% ms.skip_similarity_matrix       = 'y';
% ms.skip_aligned_image_generation= 'y';
% ms.base_output_dir              = '/nobackup/flyTEM/spark_montage';
% ms.run_dir                      = ['scale_' ms.scale];
% ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
% ms.number_of_spark_nodes        = '2.0';

[zu, sID, sectionId, z, ns] = get_section_ids(rcsource, nfirst, nlast);

%% define target directores and file names for storage
%dir_rough_intermediate_store = '/nobackup/flyTEM/khairy/FAFB00v13/montage_scape_pms';
target_solver_path = [dir_rough_intermediate_store '/solver_' num2str(nfirst) '_' num2str(nlast) ];
target_ids = [target_solver_path '/ids.txt'];
target_matches = [target_solver_path '/matches.txt'];
target_layer_images = [target_solver_path];
    disp('Target layer images stored at:');
    disp(target_layer_images);
    disp('Matches stored at:');
    disp(target_matches);
    disp('Ids stored at:');
    disp(target_ids);
    
if run_now==0
    precalc_ids = target_ids;
    precalc_matches = target_matches;
    precalc_path = target_solver_path;
end


%% [2] START SPARK: generate montage-scapes and montage-scape point-matches
if run_now==1
    [L2, needs_correction, pmfn, zsetd, zrange, t,dir_spark_work,...
        cmd_str, fn_ids, missing_images, existing_images] = ...
        generate_montage_scapes_SIFT_point_matches(ms, run_now);
elseif run_now ==-1  % only montage scapes have been generated, we need to do everything else
    dir_spark_work = [ms.base_output_dir '/' ms.project '/' ms.stack  '/' ms.run_dir];
    source_layer_images = [dir_spark_work '/layer_images'];
    fn = dir([source_layer_images '/*.png']);
    tiles(numel(fn)) = tile;  % generate an array of tiles
    for tix = 1:numel(tiles)
        tiles(tix).path = [source_layer_images '/' fn(tix).name];
        tiles(tix).z = tix;
        tiles(tix).id = tix;
        tiles(tix).sectionId = num2str(tix);
        tiles(tix).renderer_id = num2str(tix);
        tiles(tix).fetch_local = 1;
    end
    missing_images = [];
    L2 = Msection(tiles);
elseif run_now ==0
    [L2, needs_correction, pmfn, zsetd, zrange, t,dir_spark_work,...
        cmd_str, fn_ids, missing_images, existing_images] = ...
        generate_montage_scapes_SIFT_point_matches(ms, run_now, precalc_ids, precalc_matches, precalc_path);
end

%% organize directories/files and store intermediate data
source_layer_images = [dir_spark_work '/layer_images'];
if run_now==1
    kk_mkdir(target_layer_images);
    movefile(source_layer_images, target_layer_images);
    movefile(pmfn, target_matches);
    movefile(fn_ids, target_ids);
    disp('Target layer images stored at:');
    disp(target_layer_images);
    disp('Matches stored at:');
    disp(target_matches);
    disp('Ids stored at:');
    disp(target_ids);
end

if run_now==-1
    kk_mkdir(target_layer_images);
    movefile(source_layer_images, target_layer_images);
end

[zu, sID, sectionId, z, ns, zuf] = get_section_ids(rcsource, nfirst, nlast);
zuf(find(intersect(zu, missing_images))) = [];

for imix = 1:numel(zuf)
    fn_im = sprintf('%s/layer_images/%.1f.png', target_solver_path,zuf(imix));
    L2.tiles(imix).path = fn_im;
    L2.tiles(imix).fetch_local = 1;
    t(imix).path = fn_im;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% hack for Allen dataset: build pm struct using SURF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(ms, 'center_box'), ms.center_box = 1.0;end  % comment this out to use the center box
if  ms.center_box<1.0
    
    %configure
    bfac = ms.center_box;   % confine to scaled down box around center
    nbrs = 2;     % how far out to search for partners
    thresh = 3;   % minimum # of point-pairs
    pmscale = 1.0;
    %%%%%%%%%%%%%%%
    disp('Applying hack to only allow central point-matches to be used');
    for lix = 1:numel(L2.tiles) % loop over montage scapes
        L2.tiles(lix).SURF_MetricThreshold = 500;
        L2.tiles(lix).SURF_NumOctaves = 2;
        L2.tiles(lix).SURF_NumScaleLevels = 8;
        L2.tiles(lix).SURF_MaxFeatures = 1000;
        L2.tiles(lix).featuresMethod = 'SURF';%'MSER';%'FAST_SURF';%'BRISK';%'HARRIS';
    end
    L2 = calculate_tile_features(L2, 'false', 1, pmscale);
    
    for lix = 1:numel(L2.tiles) % loop over montage scapes
        X{lix} = L2.tiles(lix).validPoints.Location;
    end
    
    
    % determine allowed box
    for lix = 1:numel(L2.tiles)
        b = [min(X{lix}) max(X{lix})];
        center = [(b(3)-b(1))/2 (b(4)-b(2))/2];
        xrange = b(3)-b(1);
        yrange = b(4)-b(2);
        dx = xrange*bfac;
        dy = yrange*bfac;
        %disp([cm b xrange yrange]);
        box{lix} = [center(1)-dx center(2)-dy center(1)+dx center(2)+dy];
        %disp(box{lix});
    end
    
    % plot(X{1}(:,1), X{1}(:,2), '*k');
    % hold on;rectangle('Position', [box{1}(1) box{1}(2) box{1}(3)-box{1}(1) box{1}(4)-box{1}(2)]);
    
    %%% restrict point-matches within sets to the allowed box
    for lix = 1:numel(L2.tiles) % loop over montage scapes
        disp(lix);
        del_indx = [];
        for pix = 1:size(X{lix},1)
            X1 = X{lix}(pix,:);
            t1 = lix;
            if ~(X1(1)>box{t1}(1) && X1(1)<box{t1}(3) ...
                    && X1(2)>box{t1}(2) && X1(2)<box{t1}(4))
                del_indx = [del_indx;pix];   % mark this point-pair for deletion
            end
        end
        %L2.tiles(lix).features(del_indx,:) = [];
        L2.tiles(lix).validPoints(del_indx) = [];
    end
    

%     plot(L2.tiles(1).validPoints.Location(:,1), L2.tiles(1).validPoints.Location(:,2), '*k');
%     hold on;rectangle('Position', [box{1}(1) box{1}(2) box{1}(3)-box{1}(1) box{1}(4)-box{1}(2)]);
%     
    
    %%% determine point matches
    
    ntiles = numel(L2.tiles);
    A = zeros(ntiles, 'logical');
    for rix = 1:ntiles
        for cix = rix:ntiles
            if (cix-rix)>=1 && (cix-rix)<nbrs+1,
                A(rix,cix) = 1;
            end
        end
    end
    L2.A = A;
    [r, c] = ind2sub(size(L2.A), find(L2.A));  % neighbors are determined by the adjacency matrix
    mL2_tiles = L2.tiles;
    M = cell(numel(r),2);
    adj = zeros(numel(r),2);
    W = cell(numel(r),1);
    np = zeros(numel(r),1);
    delpix = zeros(numel(r),1, 'uint32');
    %count = 1;
    disp('Calculating point matches using parfor .... ');
    tic
    parfor_progress(numel(r));
    parfor pix = 1: numel(r)
        disp(['Point matching: ' num2str(pix) ' of ' num2str(numel(r))]);
        %     try
        %disp(['Calculating point-match set: ' num2str(pix) ' of ' num2str(numel(r))]);
        f1 = mL2_tiles(r(pix)).features;
        f2 = mL2_tiles(c(pix)).features;
        vp1 = mL2_tiles(r(pix)).validPoints;
        vp2 = mL2_tiles(c(pix)).validPoints;
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %[m1, m2, ~]  = im_pair_match_features(f1, vp1, f2, vp2);
        index_pairs = matchFeatures(f1, f2, 'MatchThreshold', 10,'Method', 'NearestNeighborRatio');        % no assumption about transformation is made here
        
        if size(index_pairs,1)<3
            m1 = [];%SURFPoints();
            m2 = [];%SURFPoints();
            tform_matrix = [];
        else
            m1  = vp1(index_pairs(:,1));
            m2  = vp2(index_pairs(:,2));
            
            
            % disp('Estimating geometric transform');tic
            % [tform,m2,m1] = estimateGeometricTransform(m2.Location,m1.Location, 'affine');
            % tform_matrix = tform.T;
            % disp('Done');toc
            
            warning off;
            % %%% constructing the geoTransformEst object requires providing a
            % %%% transformation
            geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
            geoTransformEst.Method = 'Random Sample Consensus (RANSAC)';%'Least Median of Squares';
            geoTransformEst.Transform = 'Nonreflective similarity';%'Affine';%'Affine';%
            geoTransformEst.NumRandomSamplingsMethod = 'Desired confidence';
            geoTransformEst.MaximumRandomSamples = 100;
            geoTransformEst.DesiredConfidence = 95.0;
            
            
            % Invoke the step() method on the geoTransformEst object to compute the
            % transformation from the |distorted| to the |original| image. You
            % may see varying results of the transformation matrix computation because
            % of the random sampling employed by the RANSAC algorithm.
            [tform_matrix, inlierIdx] = step(geoTransformEst, m2.Location, m1.Location);
            m1 = m1(inlierIdx).Location;
            m2 = m2(inlierIdx).Location;
            %%%%%%%%%%%%%%%%%%%%
            warning on;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        M(pix,:) = {[m1]/pmscale,[m2]/pmscale};
        adj(pix,:) = [r(pix) c(pix)];
        W(pix) = {[ones(size(m1,1),1) * 1/(1+ abs(mL2_tiles(r(pix)).z-mL2_tiles(c(pix)).z))]};
        np(pix)  = size(m1,1);
        %%%% mark for removal point-matches that don't have enough point pairs
        if size(m1,1)<thresh
            delpix(pix) = 1;
        end
        
        %     catch err_pmatching
        %         kk_disp_err(err_pmatching);
        %         delpix(pix) = 1;
        %     end
        parfor_progress
    end
    parfor_progress(0);
    
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
    
    L2.pm.M = M;
    L2.pm.adj = adj;
    L2.pm.W = W;
    L2.pm.np = np;
    L2.pm
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if needs_correction==0
    %% [3] rough alignment solve for montage-scapes
    disp('Solving');
    % solve
    rigid_opts.apply_scaling = 1;
    if isfield(ms, 'FAFB')
        rigid_opts.FAFB = ms.FAFB;   % 0 means it is not FAFB dataset
    else 
        rigid_opts.FAFB = 0;   % 0 means it is not FAFB dataset
    end
    rc = rcsource;
    [zu, sID, sectionId, z, ns] = get_section_ids(rc, min(zu), max(zu));
    scale_fac = ones(numel(zu),1);
    
    if rigid_opts.FAFB
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%% specify scale factor based on autoloader vs. no autoloader
        
        fac = 1/0.935;
        wo = weboptions('Timeout', 60);
        for zix = 1:numel(zu)        %% loop over sections and identify scaling of first tile
            urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
                rc.baseURL, rc.owner, rc.project, rc.stack,zu(zix) );
            j = webread(urlChar, wo);
            sl = j(1).transforms.specList;   % spec list
            if numel(sl)==4, scale_fac(zix) = fac;end   % four transformations means autoloader
            %         disp([zix zu(zix) numel(sl)]);
            %         for trix = 1:numel(sl)
            %             disp(sl(trix));
            %         end
        end
        
    end
    rigid_opts.scale_fac = scale_fac;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if nargin>=13
        %%% reduce size for testing
        disp('reducing section size ---------------------------------------');
        num_sections_test = solve_last-solve_first + 1;
        [zu, sID, sectionId, z, ns] = get_section_ids(rc, solve_first, solve_last);
        scale_fac = ones(numel(zu),1);
        
        L2 = reduce_to_tile_subset(L2, find(zu==solve_first):find(zu==solve_last));
        L_montage = Msection;
        rctarget_rough.stack = solve_name;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % solve montage scape system
    [mL3, errR, mLS] = get_rigid_approximation(L2, 'backslash', rigid_opts);  % generate rigid approximation to use as regularizer
     solver_opts.lambda = 1e3;
     solver_opts.edge_lambda = 1e3;
    if isfield(ms, 'rough_solve')
	if strcmp(ms.rough_solve, 'affine')
          disp('using affine model for rough alignment');
          [mL3, errA] = solve_affine_explicit_region(mL3, solver_opts); % obtain an affine solution
	end
    else
	disp('using rigid model only for rough alignment');
   end
    


%%% sosi--- make sure solver did something
for tix = 1:numel(L2.tiles)
disp([tix zu(tix) L2.tiles(tix).tform.T([1 2 4 5])  mL3.tiles(tix).tform.T([1 2 4 5])]);
end

% for tix = 1:numel(L2.tiles)
% disp([tix zu(tix) L2.tiles(tix).tform.T([1 2 4 5])]);
% end



    %%%%%%%%%%%%%%%%%%%%%%%%%
    mL3s = split_z(mL3);
    
    % % [4] apply rough alignment to montaged sections (L_montage) and generate "rough_aligned" collection  %% %%%%%% sosi
    disp('Apply rough alignment to full set of montaged sections:');
    indx = find(zu-floor(zu)>0);
    zu(indx) = [];
    % load montages
    disp('-- Loading montages (typical time for large FAFB sections and 32 workers --> 150 seconds)');
    tic
    parfor zix = 1:numel(zu)
        disp(zix);
        L_montage(zix) = Msection(rctarget_montage, zu(zix));
    end
    toc
    
    
    %%%% apply rough alignment solution to montages
    disp('-- Retrieve bounding box for each section (typical time for large FAFB sections and 32 workers --> 415 seconds');
    tic
    %%% this is really slow .... speed up --- sosi
    for lix = 1:numel(L_montage)
        disp(lix);
        L_montage(lix) = get_bounding_box(L_montage(lix));
    end
    mL3.update_tile_info_switch = -1;
    mL3 = get_bounding_box(mL3);
    Wbox = [mL3.box(1) mL3.box(3) mL3.box(2)-mL3.box(1) mL3.box(4)-mL3.box(3)];disp(Wbox);
    wb1 = Wbox(1);
    wb2 = Wbox(2);
    toc
    
    
    %%%%%%%%%%%%%%
    disp('-- Perform transformation for all tiles in each section  (typical time for large FAFB sections and 32 workers --> 1000 seconds (7 minutes)');
    kk_clock;
    tic
    fac = str2double(ms.scale); %0.25;
    smx = [fac 0 0; 0 fac 0; 0 0 1]; %scale matrix
    invsmx = [1/fac 0 0; 0 1/fac 0; 0 0 1];
    tmx2 = [1 0 0; 0 1 0; -wb1 -wb2 1]; % translation matrix for montage_scape stack
    mL3T = cell(numel(L_montage),1);
    for lix = 1:numel(L_montage)
        
        %disp(lix)
        %%% sosi -- revise and generalize to use polynomials
        
        %%% limited to Affine
        mL3T{lix} = mL3s(lix).tiles(1).tform.T;  % only one tile per section (montage scapes)
    end
    disp('loop to update montage sections ......');
    %%%% sosi ---- again... this takes too long, consider for instead of parfor
    parfor lix = 1:numel(L_montage)
        disp(lix);
        b1 = L_montage(lix).box;
        dx = b1(1);dy = b1(3);
        tmx1 = [1 0 0; 0 1 0; -dx -dy 1];  % translation matrix for section box
        
        tiles = L_montage(lix).tiles;
        T3 = mL3T{lix};
        for tix = 1:numel(L_montage(lix).tiles)
            newT = tiles(tix).tform.T * tmx1 * smx * T3 * tmx2 * (invsmx);
            tiles(tix).tform.T = newT;
        end
        [x1, y1] = get_tile_centers_tile_array(tiles);
        L_montage(lix).tiles = tiles;
        L_montage(lix).X = x1;
        L_montage(lix).Y = y1;
    end
    opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
    disp('Concatenating ....');
    L_montage = concatenate_tiles(L_montage);
    toc
    disp('done');
% %     kk_clock;
% %     %%% ingest into renderer database as rough collection
% %     disp('-- Ingest into renderer database using overwrite. typical time: 15 minutes for large FAFB slab and 32 workers');
% %     kk_clock;
% %     tic
% %     ingest_section_into_renderer_database_overwrite(L_montage,rctarget_rough, rcsource, pwd);
% %     toc
% %     kk_clock;
% %     disp('Done!');    % save


% %     try
% %         fn = sprintf('%s/rough_aligned_slab_%d_%d.mat', dir_store_rough_slab, nfirst, nlast);
% %         disp(['Saving rough aligned slab binary to ' fn ' ...']);
% %         save(fn, 'L_montage', 'rctarget_rough', 'rcsource');
% %         disp('Done!');
% %     catch err_save
% %         kk_disp_err(err_save);
% %     end

end
%%%
%% Step 5: ingest into Renderer database
opts.disableValidation = 1;
rcout = rctarget_rough;
rc = rcsource;
ntiles = numel(L_montage.tiles);
Tout = zeros(ntiles,6);
tiles = L_montage.tiles;
for tix = 1:ntiles
   Tout(tix,:) = tiles(tix).tform.T(1:6)';
end
tIds = cell(ntiles,1);
for tix = 1:ntiles
 tIds{tix} = L_montage.tiles(tix).renderer_id;
end
z_val = zeros(ntiles,1);
for tix = 1:ntiles
 z_val(tix)= L_montage.tiles(tix).z;
end

disp('** STEP 5:   Ingesting data .....');
disp(' ..... translate to +ve space');
delta = 0;
dx = min(Tout(:,3)) + delta;%mL.box(1);
dy = min(Tout(:,6)) + delta;%mL.box(2);
for ix = 1:size(Tout,1)
    Tout(ix,[3 6]) = Tout(ix, [3 6]) - [dx dy];
end

disp('... export to MET (in preparation to be ingested into the Renderer database)...');

v = 'v1';
if stack_exists(rcout)
    resp = create_renderer_stack(rcout);
end
if ~stack_exists(rcout)
    disp('.... target collection not found, creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rcout);
end

chks = round(ntiles/128);
cs = 1:chks:ntiles;
cs(end) = ntiles;
disp(' .... ingesting ....');
parfor ix = 1:numel(cs)-1
    disp(ix);
    vec = cs(ix):cs(ix+1);
    export_to_renderer_database(rcout, rc, pwd, Tout(vec,:),...
        tIds(vec), z_val(vec), v, opts.disableValidation);
end


% % complete stack
disp(' .... completing stack...');
resp = set_renderer_stack_state_complete(rcout);
disp('.... done!');
diary off;

    disp('Target layer images stored at:');
    disp(target_layer_images);
    disp('Matches stored at:');
    disp(target_matches);
    disp('Ids stored at:');
    disp(target_ids);
%%%%%%%
