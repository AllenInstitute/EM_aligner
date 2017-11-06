function [err,R, Tout, A, b, map_id, tIds, z_val] = ...
    system_solve_rigid_approximation(...
    nfirst, nlast, rc, pm, opts, rcout)
% Fast solve and ingest of section alignment when regularizer (starting collection)
% rc and full set of point-matches pm is provided
% After solving, ingests solved tiles into Renderer collection rcout if non empty
%
% INPUTS:
% nfirst and nlast: z values (inclusive) to specify slab range
% rc: source stack (usually roughly aligned) that will be used to determine
%     regularization
% pm: one or more (array) of point-match structs that defines (multiple)
%     sources of point-match collections to look for point-matches
% opts: See example opts below
% rcout: fine-aligned output collection
%
% OUTPUTS:
%   err: total error of objective system (norm(Ax-b))
%   R  : residual of regularized system (K*x2-Lm)
%   Tout: solution vector
%
% Note 1 : For fast direct solution of large systems (>250k tiles) please
%         install and setup PaSTiX and set opts.solver to 'pastix'
% Note 2 : For iterative solution of large systems set opts.solver to
%          gmres or bicgstab
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% prepare quantities
if ~isfield(opts, 'transfac'), opts.transfac = 1.0;end
if ~isfield(opts, 'nchunks_ingest'), opts.nchunks_ingest = 32;end
if ~isfield(opts, 'disableValidation'), opts.disableValidation = 1;end
if ~isfield(opts, 'transfac'), opts.transfac = 1;end
if ~isfield(opts, 'filter_point_matches'), opts.filter_point_matches = 1;end
if ~isfield(opts, 'use_peg'), opts.use_peg = 0;end
if ~isfield(opts, 'nbrs_step'), opts.nbrs_step = 1;end
if ~isfield(opts, 'delete_existing_collection'), opts.delete_existing_collection = 1; end

err = [];
R = [];
xout = [];
dir_scratch = [opts.dir_scratch '/temp_' num2str(randi(3000000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);

% obtain actual section zvalues in given range their ids and also of possible reacquires
[zu, sID, sectionId, z, ns] = get_section_ids(rc, nfirst, nlast);

%% Step 1: load transformations, tile ids
% load all tiles in this range and pool into Msection object
disp('Loading transformations and tile/canvas ids from Renderer database.....');
[T, map_id, tIds, z_val] = load_all_transformations(rc, zu, dir_scratch);


ntiles = size(T,1);
disp(['..system has ' num2str(ntiles) ' tiles...']);
%[L, map_id, tIds] = load_all_tiles(rc,zu);ntiles = numel(L.tiles);
%     degree = opts.degree;
%     tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
%     tdim = tdim * 2;        % because we have two dimensions, u and v.
%
tdim = 6;
btdim = 4; % similarity
ncoeff = ntiles*btdim;
disp('....done!');diary off;diary on;
%% Step 2: Load point-matches
[M, adj, W, np] = system_solve_helper_load_point_matches(...
    zu, opts, pm, map_id, sID, ntiles);
PM.M = M;
PM.adj = adj;
PM.W = W;
PM.np = np;

if opts.use_peg
    %% generate new point-match entries to connect all tiles -- may not work for massive data yet
    tvalid = unique(PM.adj(:));  % lists all tiles that have connections to other tiles through point-matches
    if ~isempty(tvalid)
        M = cell(numel(tvalid),2);
        Weights = cell(numel(tvalid),1);
        adj = zeros(numel(tvalid),2);
        largetileix = ntiles + 1;   % linear index of fictitious tile
        np = zeros(1, numel(tvalid));
        % we need to get width and height information about all tvalid tile
        % we are assuming all tiles have same width and height here
        urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s', ...
            rc.baseURL, rc.owner, rc.project, rc.stack, tIds{tvalid(1)});
        j = webread(urlChar);
        W = j.width;
        H = j.height;
        for ix = 1:numel(tvalid)  % loop over tiles that are registered as having point-matches to other tiles
            tix = tvalid(ix);
            bb = [0 0 1;W 0 1;0 H 1;W H 1];  % base is 4 corner points
            aa = [rand(opts.peg_npoints-4,1)*W rand(opts.peg_npoints-4,1)...
                *H ones(opts.peg_npoints-4,1)]; % add additional point to top up to n
            bo = [aa;bb];
            tform = [T(tix,1) T(tix,4) 0; T(tix,2) T(tix,5) 0;T(tix,3) T(tix,6) 1];
            p = bo*tform;
            pt = p(:,1:2);
            M{ix,1} = bo(:,[1 2]);
            M{ix,2} = pt;
            adj(ix,:) = [tix largetileix];
            np(ix) = opts.peg_npoints;
            Weights{ix} = ones(1,opts.peg_npoints) * opts.peg_weight ;
        end
        PM.M = [PM.M;M];
        PM.adj = [PM.adj;adj];
        PM.W = [PM.W;Weights];
        PM.np = [PM.np;np'];
    end
    T(end+1,:) = [1 0 0 1 0 0];   % add the fictitious tile
    tIds(end+1) = {'-8888'};
    ntiles = ntiles + 1;
    ncoeff = ncoeff + btdim;
end

M = PM.M;
adj = PM.adj;
W = PM.W;
np = PM.np;


disp(' ..... done!');diary off;diary on;
%% Step 3: generate row slabs of matrix A

disp('** STEP 3:    Generating system matrix .... ');
split = opts.distribute_A;

npm = size(np,1);
disp(' .... determine row positions of point-pairs (needed for generation of A)...');
n = 4*sum(np);
r_sum_vec = [1;cumsum(4*np(1:npm-1))+1];
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
    fn_split{ix} = [dir_scratch '/split_PM_' num2str(nfirst)...
        '_' num2str(nlast) '_'...
        num2str(randi(10000000000)) '_' num2str(ix) '.mat'];
    vec = r(ix,1):r(ix,2);
    m = M(vec,:);
    a = adj(vec,:);
    ww = W(vec);
    save(fn_split{ix}, 'm', 'a', 'ww');
end
clear M adj W
diary off;diary on;


disp(' .... generate matrix slabs');%-----------------------
degree = opts.degree;
I = {};
J = {};
S = {};
w = {};
parfor ix = 1:split
    [I{ix}, J{ix}, S{ix}, wout, Ib{ix},  Sb{ix}] = ...
        gen_A_b_row_range_similarity(fn_split{ix}, ...
        np,r_sum_vec, r(ix,1), r(ix,2));
    wout(wout==0)= [];
    w{ix} = wout;
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
Ib1 = cell2mat(Ib(:));clear Ib;
Sb1 = cell2mat(Sb(:));clear Sb;
disp('..... done!');

%% Step 4: Solve for similarity
disp('** STEP 4:   Solving ....'); diary off;diary on;
% build system and solve it
%btdim = 4; % because there is no translation
A = sparse(I1,J1,S1, n,ntiles*btdim); clear I1 J1 S1;
b = sparse(Ib1,ones(length(Ib1),1), double(Sb1),n,1);
w = cell2mat(w(:));
Wmx = spdiags(w,0,size(A,1),size(A,1));
clear w;

% eliminate first 4 columns in A because we are fixing one tile.
A = A(:, 5:end);

K  = A'*Wmx*A;
Lm  = A'*Wmx*b;
[x2, R] = solve_AxB(K,Lm, opts, []);

precision = norm(K*x2-Lm)/norm(Lm);
disp(['Simlarity Precision: ' num2str(precision)]);
err = norm(A*x2-b);
disp(['Similarity Error norm(Ax-b): ' num2str(err)]);
Error = err;
Tout = full(reshape(x2, btdim, (ncoeff-4)/btdim)');%

%% step 4': rescale all tiles to unity
parfor ix = 1:size(Tout,1)
    Tf = Tout(ix, :);
    [U S V] = svd(reshape(Tf, 2, 2));
    Tf = U * [1 0; 0 1] * V';  % rescale to unity
    Tout(ix,:) = Tf(:)';
end
% add the first tile back and add zeros to complete affine set
zer = zeros((ncoeff-4)/btdim, 1);
Tout = [ [-1 0 0 0 -1 0]; ...
    Tout(:,1) Tout(:,2) zer ...
    Tout(:,3) Tout(:,4) zer];
clear x2;
%clear K Lm d tb A b Wmx tB
disp('.... done!');

if opts.use_peg  % delete fictitious tile
    Tout(end,:) = [];
    tIds(end) = [];
    ntiles = ntiles - 1;
    ncoeff = ncoeff - tdim;
end

%% Step 5: ingest scaled similarity into Renderer database
if ~isempty(rcout)
    %%% temporary Renderer stack
    rctemp = rcout;
    rctemp.stack = [rctemp.stack '_temp_similarity'];
    
    %%%%
    disp('** STEP 5:   Ingesting data .....');
    disp(' ..... translate to +ve space');
    delta = 0;
    dx = min(Tout(:,3)) + sign(Tout(1))* delta;
    dy = min(Tout(:,6)) + sign(Tout(1))* delta;
    for ix = 1:size(Tout,1)
        Tout(ix,[3 6]) = Tout(ix, [3 6]) - [dx dy];
    end
    
    disp('... export to MET (in preparation to be ingested into the Renderer database)...');
    
    v = 'v1';
    if stack_exists(rctemp) && opts.delete_existing_collection
        disp('.... removing existing collection');
        resp = delete_renderer_stack(rctemp);
    end
    if ~stack_exists(rctemp)
        disp('.... target collection not found, creating new collection in state: ''Loading''');
        resp = create_renderer_stack(rctemp);
    end
    
    if ntiles<opts.nchunks_ingest, opts.nchunks_ingest = ntiles;end
    
    chks = round(ntiles/opts.nchunks_ingest);
    cs = 1:chks:ntiles+1;
    cs(end) = ntiles;
    disp(' .... ingesting ....');
    parfor ix = 1:numel(cs)-1
        vec = cs(ix):cs(ix+1);
        export_to_renderer_database(rctemp, rc, dir_scratch, Tout(vec,:),...
            tIds(vec), z_val(vec), v, opts.disableValidation);
    end
    
    
    % % complete stack
    disp(' .... completing stack...');
    resp = set_renderer_stack_state_complete(rctemp);
end
disp('.... done!');
diary off;

%% step 6: sove for translation 

[err,R, Tout] = system_solve_translation_support_rigid(...
    nfirst, nlast, rctemp,...
    pm, opts, rcout, Tout, map_id, tIds, z_val, PM);
delete_renderer_stack(rctemp);











