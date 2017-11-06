function [err,R, Tout, Diagnostics] = system_solve_affine_with_constraint(nfirst, nlast, rc, pm, opts, rcout)
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
%
% opts: options struct, example values and comments below:
% 
%     opts.transfac = 1e-15;                  % translation constraint (regulrization). Small values leave translation free to be optimized for
%     opts.lambda = 10^(1);                   % general regularization parameter
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % IMPORTANT --- PLEASE READ THE ENTIRE CONSTRAINTS STRATEGY:
%     % If you want to use one regularizer to constrain all tiles to their original transformations
%     % in collection rc (the source collection), then set opts.constrain_by_z to zero.
%     % when opts.constrain_by_z is set to one, then you want to have different constraints for
%     % different z sections. You still need to set opts.lambda as your "general" regularization parameter
%     % which will be used for all tiles in sections for which no other rule is specified.
%     % 
%     % When opts.constrain_by_z is set to one, you can:
%     % [a]  "sandwitch" your solution between
%     % two fixed sections (in which case you set opts.sandwitch equal to 1). In this scenario the solver fixes
%     % the sandwitching sections (nfirst and nlast) by using their "very high" constraint provided
%     % opts.constraint_fac. This essentially fixes those two sections and uses (the generally
%     % softer) regularization in opts.lambda for all tiles in the other sections.
%     % Use-cases: [1]  when re-solving a local section (or small set of sections) within a larger volume, without
%     % wanting to disturb the rest of the volume, or [2] when tissue structure biases point-matches
%     % in such a way that the affine solution introduces unwanted artificial rotation. In this
%     % latter case you want to solve using translation only and use this translation collection as
%     % the "rc" source collection here.
%     % 
%     % [b] or you want to control precisely what the regularization will be for each section. Then
%     % set opts.sandwitch to zero. Now the function expects a parameter opts.z_constraint, wich is
%     % an array of dimensions n x 2 (or 3), where n is the number of sections with special lambda values.
%     % (All tiles in other sections will simply use opts.lambda as regularization parameter).
%     % 
%     % for each of the n rows, each row needs three entries:
%     %   Entry 1: z value for this section 
%     %   Entry 2: lambda for tiles in this section
%     %   Entry 3 (optional): lambda for translation parameters of tiles in this section. This value
%     %                       overrides opts.transfac for this section.
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%     opts.constrain_by_z = 1;                % use special constraints (sandwitch or each z individually)
%     opts.sandwich = 0;                      % when set to 1 constrains first z (nfirst) and last z (nlast) by opts.constraint_fac. Note: must set opts.constrain_by_z to 1.
%     opts.constraint_fac = 1e15;             % regularization constraint for first and last z when opts.sandwich equals 1. Should be very high.
%     opts.z_constraint =[505 1e-4; 506 1e-4];% if opts.constain_by_z equals 1 and opts.sandwich
%                                             % equals zero, then list z-values and lambda
%                                             % regularization for each section whose tiles should
%                                             % have a lambda value different than opts.lambda.
%                                             % If also translation constraint should be different
%                                             % then list [z lambda tanslation_lambda] for each
%                                             % section so affected.
%     opts.degree = 1;                        % 1 = affine. Should be left equal to 1 for this function
%     opts.solver = 'backslash';              % solver type to use: backslash, gmres, bicgstab, pastix (if installed)
%     opts.nbrs = 4;                          % number of neighboring sections to consider point-matches for
%     opts.nbrs_step = 1;                     % experimental. Keep equal to 1. Skips neighboring  sections if > 1
%     opts.xs_weight = 0.1;                   % weight of cross-section point-matches / weight of montage point-matches
%     opts.inverse_dz = 1;                    % experimental. Keep equal to 1. 0 == use full weight across neighboring sections
%     opts.min_points = 3;                    % minimum number of point-matches needed to consider a tile-pair connected.
%     opts.max_points = inf;                  % maximum number of point-matches allowed per tile-pair. Use inf to take all point-matches into consideration.
%     opts.filter_point_matches = 1;          % set to 1 to filter point-matches per tile-pair using opts.pmopts struct (shown below)
%     opts.matrix_only = 0;                   % set to 0 generally. Set to one to debug the matrix. 0 = solve , 1 = only generate the matrix
%     opts.distribute_A = 1;                  % # shards of A. Keep 1 unless using pastix
%     opts.dir_scratch = '/scratch/khairyk';  % scratch directory needed for point-match loading and ingestion.
%     opts.disableValidation = 0;             % when set to 1, disables validation of tile-level bounding box performed by the Renderer service.
%     opts.translate_to_positive_space = 0;   % should the solution slab be translated to +ve space before ingestion?
%     opts.use_peg = 0;                       % generally used when solving for a montage 
%                                             % or any situation where we have mutiple disconnected (point-match) 
%                                             % clusters of tiles. Sets up a ficticious tile with connections 
%                                             % (point-matches) to every tile, so that the matrix
%                                             % system can be solved.
%     opts.peg_npoints = 5;                   % if opts.use_peg is set to 1, then opts.peg_points specifies
%                                             % the number of point-matches between each tile and the fictitions one.
%     opts.peg_weight = 1e-4;                 % keep this number small. point-match weights to
%                                             % fictitious tile should not dominate the solution.
%     
%     % configure point-match filter when opts.filter_point_matches is set to 1.
%     % Uses Matlab's RANSAC filter (see Matlab documentation)
%     opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
%     opts.pmopts.MaximumRandomSamples = 8000;
%     opts.pmopts.DesiredConfidence = 99.9;
%     opts.pmopts.PixelDistanceThreshold = 0.1;
%     opts.verbose = 0;
%     opts.debug = 0;
%     opts.Width = 2160;   % (optional)used by system_solve_helper_load_point_matches
%                          % sets general tile width and heigh. This is needed to exclude bad within-layer-point-matches
%                          % for regular layers (i.e. not reacquires), as sometimes consistent (but wrong) point-matches can occur that
%                          % are in the "middle" of tiles, i.e. do not correspond to the overlap region.
%                          % this happens usually due to matching structure in the resin.
%     opts.Height = 2560;  % if width and height are not set, it will assume FAFB values
% ------------------------
%    
% rcout: fine-aligned output collection
%
% OUTPUTS:
%   err: total error of objective system (norm(Ax-b))
%   R  : residual of regularized system (K*x2-Lm)
%   Tout: solution vector
%   Diagnostics: a struct with important diagnostic information about the solution
%   Diagnostics.timer_solve_A : time needed to solve linear system (K x Lm is what actually gets solved)
%   Diagnostics.dim_A: dimensions of A (size(A)
%   Diagnostics.nnz_A: number of non-zeros in original matrix A (that does not get solved)
%   Diagnostics.nnz_K: number of non-zeros in sparse matrix K, which gets solved
%   Diagnostics.precision: precision of matrix solution: norm(K*x-Lm)/norm(Lm)
%   Diagnostics.err: norm of residual of the orginal system A x b (not K x Lm), given by norm(A*x-b).
%                    This is the actual magnitude of point-match residuals and an important measure of
%                    how well point-matches actually match given the solution.
%  Diagnostics.tile_err: point-match error mean over each tile.
%   Diagnostics.rms: root-mean-squared error for point-match over each tile.
%
% Note 1 : For fast direct solution of large systems (>250k tiles) please
%         install and setup PaSTiX and set opts.solver to 'pastix'
% Note 2 : For iterative solution of large systems set opts.solver to
%          gmres or bicgstab
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Diagnostics = struct;

%% prepare quantities
if ~isfield(opts, 'transfac'), opts.transfac = 1.0;end
if ~isfield(opts, 'nchunks_ingest'), opts.nchunks_ingest = 32;end
if ~isfield(opts, 'disableValidation'), opts.disableValidation = 1;end
if ~isfield(opts, 'transfac'), opts.transfac = 1;end
if ~isfield(opts, 'filter_point_matches'), opts.filter_point_matches = 1;end
if ~isfield(opts, 'use_peg'), opts.use_peg = 0;end
if ~isfield(opts, 'nbrs_step'), opts.nbrs_step = 1;end


err = [];
R = [];
xout = [];
dir_scratch = [opts.dir_scratch '/temp_' num2str(randi(3000000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);
diary on;
% obtain actual section zvalues in given range their ids and also of possible reacquires
[zu, sID, sectionId, z, ns] = get_section_ids(rc, nfirst, nlast);
Diagnostics.zu = zu;
% determine W and H: used for determining deformation to decide on good lambda
if numel(opts.lambda)>1
    webopts = weboptions('Timeout', 60);
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack,zu(1));
    j = webread(urlChar, webopts);
    jt1 = tile(j(1));
    Width = jt1.W;
    Height = jt1.H;
end

%% Step 1: load transformations, tile ids
% load all tiles in this range and pool into Msection object
disp('Loading transformations and tile/canvas ids from Renderer database.....');
[T, map_id, tIds, z_val] = load_all_transformations(rc, zu, dir_scratch);
ntiles = size(T,1);
Diagnostics.ntiles = ntiles;
disp(['..system has ' num2str(ntiles) ' tiles...']);
%[L, map_id, tIds] = load_all_tiles(rc,zu);ntiles = numel(L.tiles);
degree = opts.degree;
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
ncoeff = ntiles*tdim;
disp('....done!');diary off;diary on;
%% Step 2: Load point-matches
if isfield(opts, 'PM')
    PM = opts.PM;
else
    kk_clock;
    diary off;
    diary on;
    disp('loading point matches');
    timer_load_point_matches = tic;
    if isfield(opts, 'pm_data_file')
        load(opts.pm_data_file);
    else
        
        [M, adj, W, np, discard] = system_solve_helper_load_point_matches(...
            zu, opts, pm, map_id, sID, size(T,1));
        PM.M = M;
        PM.adj = adj;
        PM.W = W;
        PM.np = np;
    end
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
        ncoeff = ncoeff + tdim;
    end
end
M = PM.M;
adj = PM.adj;
W = PM.W;
np = PM.np;
% cd(dir_scratch)
% save PM M adj W -v7.3;
% fn = [dir_scratch '/PM.mat'];
% PM = matfile(fn);
disp(' ..... done!');diary off;diary on;
%% Step 3: generate row slabs of matrix A
%%%%% Experimental: set xy to zero (after having added fictitious tile is using peg.
%     if opts.transfac<1.0  % then set x and y to 0,0 for each tile
%         % it is assumed in this case that translation has more freedom than other parameters
%         % typical case: keep everything rigid (high lambda) and really low opts.transfac
%         disp(['--- Warning: Setting all x and y to zero for starting vector']);
%         T(:,3) = 0;
%         T(:,6) = 0;
%     end
%%%%%%%%%%%%%%%%%%
timer_generate_A = tic;
disp('** STEP 3:    Generating system matrix .... ');
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
% sosi---- should be parfor, but experimenting with large matrices at the moment
for ix = 1:split
    [I{ix}, J{ix}, S{ix}, wout, Ib{ix}, Sb{ix}] = gen_A_b_row_range(fn_split{ix}, ...
        degree, np,r_sum_vec, r(ix,1), r(ix,2));
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
%% optionally save intermediate state
if isfield(opts, 'save_temp_path') && ~isempty(opts.save_temp_path)
    disp('SOSI: Saving state with I1 J1 S1 ... etc before matrix construction');
    kk_clock;
    cd opts.save_temp_path; %cd('/nrs/flyTEM/khairy/FAFB00v14/matlab_production_scripts/full_fafb_data')
    save temp_I1_J1_S1;
    disp('... done!');
    kk_clock;
end
%% Step 4: Construct matrix and solve
%      beyond this stage relevant parameters:
%                  opts.transfac
%                  opts.lambda
%                  opts.constraint_fac
%                  opts.z_constraint
%                  opts.constrain_by_z
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('** STEP 4:   Solving ....'); diary off;diary on;
lambda = opts.lambda;
disp('--------- using lambda:');
disp(lambda);
disp('-----------------------');

% build system
A = sparse(I1,J1,S1, n,ntiles*tdim); clear I1 J1 S1;
Diagnostics.timer_generate_A = toc(timer_generate_A);
b = sparse(size(A,1), 1);
w = cell2mat(w(:));
Wmx = spdiags(w,0,size(A,1),size(A,1));
clear w;
d = reshape(T', ncoeff,1);
%clear T;

% build constraints into system
lambda = opts.lambda * ones(ncoeff,1);  % defines the general default constraint
% modulate lambda accoding to opts.transfac
if opts.transfac~=1
    lambda(3:3:end) = lambda(3:3:end) * opts.transfac;
end


if isfield(opts, 'save_matrix') && opts.save_matrix
    disp('Saving matrices and settings:');
    disp([pwd '/intermediate_results.mat']);
    save intermediate_results;
    disp('Done!');
end


% constrains tiles in the stack by using full sections
if isfield(opts, 'constrain_by_z') && opts.constrain_by_z
    if isfield(opts, 'sandwich') && opts.sandwich % constrains tiles by sections nfirst and nlast
        disp('----------Constraining first and last section specified---------------');
        if ~isfield(opts, 'constraint_fac') % check if set
            opts.constraint_fac = 1e15;     % use default if not set
        end
        c = opts.constraint_fac;
        num_nfirst = sum(z_val==nfirst);
        num_nlast  = sum(z_val==nlast);
        lambda(1:tdim*num_nfirst) = c;
        lambda(end-tdim*num_nlast+1:end) = c;
    else % constrains tiles belonging to sections defined in opts.z_constraint
        for zix = 1:size(opts.z_constraint,1)
            idx = find(z_val==opts.z_constraint(zix,1)); % finds indices of tiles with this z value
            if ~isempty(idx)
                indxstart =  (idx(1) -1) * tdim + 1;
                indxend   = idx(end) * tdim;
                vec = indxstart:indxend;
                lambda(vec) = opts.z_constraint(zix,2);
                
                % constrain translation for this section
                if size(opts.z_constraint,2)>2    % then we also have translation regularizer
                    vec = indxstart+3:3:indxend;
                    lambda(vec) = opts.z_constraint(zix,3);
                end
                
            end
        end
    end
end
lambda = sparse(1:ncoeff, 1:ncoeff, lambda, ncoeff, ncoeff);
% construct final matrix
K  = A'*Wmx*A + lambda;
Lm  = A'*Wmx*b + lambda*d;
%     timer_solve_A = tic;

disp('----- Solving slab -------');
disp(['First section: ' num2str(zu(1))]);
disp(['Last section : ' num2str(zu(end))]);
disp('--------------------------');



% SOLVE
[x2, R, Diagnostics.timer_solve_A] = solve_AxB(K,Lm, opts, d);   



%     Diagnostics.timer_solve_A = toc(timer_solve_A);
Diagnostics.nnz_A = nnz(A);
Diagnostics.nnz_K = nnz(K);
%%%% sosi
%disp(full([d(:) Lm(:) diag(tB) x2(:) R(:)]));
%%%%%
precision = norm(K*x2-Lm)/norm(Lm);
disp(['Precision: ' num2str(precision)]);
err = norm(A*x2-b);
disp(['Error norm(Ax-b): ' num2str(err)]);
Error = err;
Diagnostics.precision = precision;
Diagnostics.err = err;
Diagnostics.dim_A = size(A);
Diagnostics.res =  A*x2-b;
[Diagnostics.tile_err, Diagnostics.rms, Diagnostics.delix] = system_solve_helper_tile_based_point_pair_errors(PM, Diagnostics.res, ntiles);

Tout = reshape(x2, tdim, ncoeff/tdim)';% remember, the transformations

if opts.use_peg  % delete fictitious tile
    Tout(end,:) = [];
    tIds(end) = [];
    ntiles = ntiles - 1;
    ncoeff = ncoeff - tdim;
end
% cleanup
clear x2;
clear K Lm d tb A b Wmx tB
disp('.... done!');
%% ingest into Renderer
system_solve_helper_ingest_into_renderer_database(rc, rcout, ...
    Tout, tIds, z_val, opts, zu);

