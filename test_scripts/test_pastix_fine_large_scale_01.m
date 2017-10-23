% Script to solve a FAFBv12 rough aligned slabs for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0: configure 
clc;kk_clock;

nfirst = 1;
nlast  = 2000;

% configure rough collection
rc.stack          = 'FUSED_ROUGH_01';
rc.owner          ='flyTEM';
rc.project        = 'test2';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

% configure fine output collection
rcout.stack          = ['EXP_FAFBv13_slab_' num2str(nfirst) '_' num2str(nlast) '_fine_pastix_block_A'];
rcout.owner          ='flyTEM';
rcout.project        = 'test2';
rcout.service_host   = '10.40.3.162:8080';
rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];
rcout.verbose        = 1;
rcout.versionNotes   = 'testing pastix for massive joint solution and block A generation';

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';



% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'pastix';%'backslash';%%'gmres';%'backslash';'pastix';



opts.pastix.ncpus = 16;
opts.pastix.parms_fn = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
opts.pastix.split = 1; % set to either 0 (no split) or 1
opts.pastix.linsystem_name = 'linear_system_Ab';

opts.matrix_only = 0;   % 0 = solve also
opts.distribute_A = 500;  % distribution of generation of parts of A
opts.dir_scratch = '/scratch/khairyk';


opts.min_points = 3;
opts.max_points = 100;
opts.nbrs = 3;
opts.xs_weight = 0.5;
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;

opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);
opts.A = [];
opts.b = [];
opts.W = [];

% % configure point-match filter
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 1000;
opts.pmopts.DesiredConfidence = 99.5;
opts.pmopts.PixelDistanceThreshold = 1;

opts.verbose = 1;
opts.debug = 0;


disp('---------------');
disp('Processing:');
disp(rc);
disp('---------------');
%kk_clock;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% solve system
% system_solve(nfirst, nlast, rc, pm, opts, rcout);


dir_scratch = [opts.dir_scratch '/temp_' num2str(randi(3000000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);
diary on;
% obtain actual section zvalues in given range their ids and also of possible reacquires
[zu, sID, sectionId, z, ns] = get_section_ids(rc, nfirst, nlast);
%% Step 1: load transformations, tile ids
% load all tiles in this range and pool into Msection object
disp('STEP 1: Loading transformations and tile/canvas ids from Renderer database.....');
[T, map_id, tIds, z_val] = load_all_transformations(rc, zu, dir_scratch);
ntiles = size(T,1);
degree = opts.degree;
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
ncoeff = ntiles*tdim;

d = reshape(T', ncoeff,1);clear T;
disp(['..system has ' num2str(ntiles) 'tiles...']);
%[L, map_id, tIds] = load_all_tiles(rc,zu);ntiles = numel(L.tiles);
disp('....done!');diary off;diary on;
%% Step 2: Load point-matches
disp('** STEP 2:  Load point-matches ....'); 
disp(' ... predict sequence of PM requests to match sequence required for matrix A');
sID_all = {};
fac = [];
ismontage = [];
count  = 1;
for ix = 1:numel(zu)   % loop over sections
    %disp(['Montage: ' sID{ix}]);
    sID_all{count,1} = sID{ix};
    sID_all{count,2} = sID{ix};
    ismontage(count) = 1;
    fac(count) = 1;
    count = count + 1;
    for nix = 1:opts.nbrs   % loop over neighboring sections
        if (ix+nix)<=numel(zu)
            %disp(['cross-layer: ' num2str(ix) ' ' sID{ix} ' -- ' num2str(nix) ' ' sID{ix+nix}]);
            sID_all{count,1} = sID{ix};
            sID_all{count,2} = sID{ix+nix};
            ismontage(count) = 0;
            fac(count) = 1/(nix+1);
            count = count + 1;
        end
    end
end
% % perform pm requests
disp('Loading point-matches from point-match database ....');
wopts = weboptions;
wopts.Timeout = 20;
M   = {};
adj = {};
W   = {};
np = {};  % store a vector with number of points in point-matches (so we don't need to loop again later)
parfor ix = 1:size(sID_all,1)   % loop over sections
    %disp([sID_all{ix,1}{1} ' ' sID_all{ix,2}{1} ' ' num2str(ismontage(ix))]);
    if ismontage(ix)
        [m, a, w, n] = load_montage_pm(pm, sID_all{ix,1}, map_id,...
            opts.min_points, opts.max_points, wopts);
    else
        [m, a, w, n] = load_cross_section_pm(pm, sID_all{ix,1}, sID_all{ix,2}, ...
            map_id, opts.min_points, opts.max_points, wopts, fac(ix));
    end
    M(ix) = {m};
    adj(ix) = {a};
    W(ix) = {w};
    np(ix) = {n};  
end
disp('... concatenating point matches ...');
% concatenate
M = vertcat(M{:});
adj = vertcat(adj{:});
W   = vertcat(W{:});
np  = [np{:}]';

% cd(dir_scratch)
% save PM M adj W -v7.3;
% fn = [dir_scratch '/PM.mat'];
% PM = matfile(fn);

disp(' ..... done!');diary off;diary on;
%% Step 3: generate row slabs of matrix A
disp('** STEP 3:    Generating primary system matrix A .... ');
split = opts.distribute_A;

npm = size(np,1);
disp(' .... determine row positions of point-pairs (needed for generation of A)...');
n = 2*sum(np);
r_sum_vec = [1;cumsum(2*np(1:npm-1))+1];
pm_per_worker = round(npm/split);
disp([' .... pm_per_worker=' num2str(pm_per_worker)]);
r = zeros(split,2);
for ix=1:split
    pm_min = 1 + (ix-1)*pm_per_worker;
    if ix < split
        pm_max = pm_min   + pm_per_worker-1;
    else
        pm_max = npm;
    end
    r(ix,:) = [pm_min pm_max];
end
indx = find(r(:,1)>npm);
r(indx,:) = [];
r(end,2)  = npm;
split = size(r,1);


disp(' .... export temporary files split_PM_*.mat...');%-----------------------
fn_split = cell(split,1);
for ix = 1:split
    fn_split{ix} = [dir_scratch '/split_PM_' num2str(nfirst) '_' num2str(nlast) '_' num2str(randi(10000000)) '_' num2str(ix) '.mat'];
    vec = r(ix,1):r(ix,2);
    m = M(vec,:);
    a = adj(vec,:);
    ww = W(vec);
    save(fn_split{ix}, 'm', 'a', 'ww');
end
clear M adj W
diary off;diary on;


disp(' .... generate matrix slabs');%-----------------------
degree = 1;

% determine column ranges
col_per_worker = round(ncoeff/opts.pastix.ncpus);
c = zeros(opts.pastix.ncpus,2);
for ix=1:opts.pastix.ncpus
    col_min = 1 + (ix-1)*col_per_worker;
    if ix < opts.pastix.ncpus
        col_max = col_min   + col_per_worker-1;
    else
        col_max = ncoeff;
    end
    c(ix,:) = [col_min col_max];
end
indx = find(c(:,1)>ncoeff);
c(indx,:) = [];
c(end,2)  = ncoeff;
if size(c,1)~=opts.pastix.ncpus,
    disp('Adjusting ncpus');
    opts.pastix.ncpus = size(c,1);
    disp(opts.pastix.ncpus);
end

% I = {};
% J = {};
% S = {};
w = {};
fn_split_col = {};
ncpus = opts.pastix.ncpus;
disp(' ............ read point-matches for each row-wise slab, fragment into blocks and save');
for ix = 1:split  % loop over slabs
    disp(ix);
    [I, J, S, wout] = gen_A_b_row_range(fn_split{ix}, ...
        degree, np,r_sum_vec, r(ix,1), r(ix,2));  % generate slab from point-match file
    wout(wout==0)= [];
    w{ix} = wout;  % aggregate w only
    a = sparse(I,J,S,n, ntiles*tdim);
    % set up new directory for splitting this slab into chuncks/blocks
    dir_scratch_col_split = [dir_scratch '/tmp_col_split_' ...
        num2str(ix) '_' num2str(randi(10000000000))];
    kk_mkdir(dir_scratch_col_split);
    for cix = 1:ncpus  % loop over column ranges --- save the relevant column
        disp([ix cix]);
        fn_split_col{ix, cix} = [dir_scratch_col_split '/chnk_mx_aa_col_' ...
                    num2str(nfirst) '_' num2str(nlast) ...
                    '_' num2str(cix) 'slab_' num2str(ix) '.mat'];
        fn = [dir_scratch_col_split '/chnk_mx_aa_col_' ...
                    num2str(nfirst) '_' num2str(nlast) ...
                    '_' num2str(cix) 'slab_' num2str(ix) '.mat'];
        aa = a(:, c(cix,1):c(cix,2));
        save_aa(fn, aa);  % save the sparse block
    end
end

disp(' ........... read column blocks and aggregate, then export into column shards');
dir_scratch_shards = [dir_scratch '/tmp_col_split_' ...
        num2str(ix) '_' num2str(randi(10000000000))];
    kk_mkdir(dir_scratch_shards);  
fn_A_shards = {};
linsystem_name = opts.pastix.linsystem_name;
parfor cix = 1:opts.pastix.ncpus
    A = [];
    for rix = 1:split
        mat = load(fn_split_col{rix,cix});
        A = [A;mat.aa];
    end
    fn_A_shards{cix} = [dir_scratch_shards '/' linsystem_name ...
                        '_', num2str(cix), '.mat'];
    save_Ab(fn_A_shards{cix}, A, cix, c);
end


dir_scratch_K_shards = [dir_scratch '/tmp_K_col_split_' ...
        num2str(ix) '_' num2str(randi(10000000000))];
    kk_mkdir(dir_scratch_K_shards);  
fn_K_shards = {};
linsystem_name = opts.pastix.linsystem_name;

% we now have a set of columns of the matrix A
% next we need to generate columns of K and blocks of Lm
for cix = 1:ncpus
    b = opts.lambda*d(c(cix,1):c(cix,2));
    A = sparse(c(end), numel(1:numel(c(cix,1):c(cix,2))));
    mat = load(fn_A_shards{cix});
    A1 = mat.A;
    for rix = 1:ncpus
        disp([cix rix]);
        if cix~=rix
            mat = load(fn_A_shards{rix});
            A2 = mat.A;
            A(c(rix,1):c(rix,2), c(cix,1):c(cix,2)) = A2'*A1;
        else
           A(c(rix,1):c(rix,2), c(cix,1):c(cix,2)) = A1'*A1;
        end
    end
    fn_K_shards{cix} = [dir_scratch_K_shards '/' linsystem_name ...
        '_', num2str(cix), '.mat'];
    save_KLm(fn_K_shards{cix}, A, b, cix, c);
end










% delete/cleanup
for ix = 1:split
    try
    delete(fn_split{ix});
    catch err_delete
        kk_disp_err(err_delete);
    end
end


% % collect matrix slabs into one matrix A
disp('.... collect: generate the sparse matrix from I, J and S');
I1 = cell2mat(I(:));clear I;
J1 = cell2mat(J(:));clear J;
S1 = cell2mat(S(:));clear S;
disp('..... done!');
%% Step 4: Solve
disp('** STEP 4:   Solving ....'); diary off;diary on;
% build system and solve it
A = sparse(I1,J1,S1, n,ntiles*tdim); clear I1 J1 S1;
b = sparse(size(A,1), 1);
w = cell2mat(w(:));
Wmx = spdiags(w,0,size(A,1),size(A,1));
clear w;
tB = ones(ncoeff,1);
tB = sparse(1:ncoeff, 1:ncoeff, tB, ncoeff, ncoeff);
K  = A'*Wmx*A + opts.lambda*(tB')*tB;
Lm  = A'*Wmx*b + opts.lambda*(tB')*d;
[x2, R] = solve_AxB(K,Lm, opts, d);
Tout = reshape(x2, tdim, ncoeff/tdim)';% remember, the transformations
disp('.... done!');
%% Step 5: ingest into Renderer database

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
    disp('.... removing existing collection');
    resp = create_renderer_stack(rcout);
end
if ~stack_exists(rcout)
    disp('.... target collection not found, creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rcout);
end

chks = round(ntiles/32);
cs = 1:chks:ntiles;
cs(end) = ntiles;
disp(' .... ingesting ....');
parfor ix = 1:numel(cs)-1
    vec = cs(ix):cs(ix+1)-1;
    export_to_renderer_database(rcout, rc, dir_scratch, Tout(vec,:),...
                                tIds(vec), z_val(vec), v);
end


% % complete stack
disp(' .... completing stack...');
resp = set_renderer_stack_state_complete(rcout);
disp('.... done!');
diary off;











