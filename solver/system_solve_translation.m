function [err,R, Tout, PM, Diagnostics] = system_solve_translation(nfirst, nlast, rc, pm, opts, rcout)
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

if opts.degree>1
    [err,R, Tout] = system_solve_polynomial(nfirst, nlast, rc, pm, opts, rcout);
else
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
    
    % determine W and H: used for determining deformation to decide on good lambda
%     if numel(opts.lambda)>1
%         webopts = weboptions('Timeout', 60);
%         urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
%             rc.baseURL, rc.owner, rc.project, rc.stack,zu(1));
%         j = webread(urlChar, webopts);
%         jt1 = tile(j(1));
%         Width = jt1.W;
%         Height = jt1.H;
%     end
    
    %% Step 1: load transformations, tile ids
    % load all tiles in this range and pool into Msection object
    disp('Loading transformations and tile/canvas ids from Renderer database.....');
    [T, map_id, tIds, z_val] = load_all_transformations(rc, zu, dir_scratch);
    
    
    ntiles = size(T,1);
    disp(['..system has ' num2str(ntiles) ' tiles...']);
    degree = opts.degree;
    tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
    tdim = tdim * 2;        % because we have two dimensions, u and v.
    ncoeff = ntiles*tdim;
    disp('....done!');diary off;diary on;
    %% Step 2: Load point-matches
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

%%% uncomment to test for number of connected components (should be one)
%%% could take up a lot of time/memory to do for large PM structs
indx = sub2ind([ntiles ntiles], PM.adj(:,1), PM.adj(:,2));
indx = [indx; sub2ind([ntiles ntiles], PM.adj(:,2), PM.adj(:,1))];
A = sparse(ntiles,ntiles);
A(indx) = 1;
G = graph(A);
c = conncomp(G);
nbins = max(c);
disp(['Number of connected components: ' num2str(nbins)]);
if nbins>1, error(' Number of connected components in point-match graph cannot exceed one');end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

M = PM.M;
adj = PM.adj;
W = PM.W;
np = PM.np;
% cd(dir_scratch)
% save PM M adj W -v7.3;
% fn = [dir_scratch '/PM.mat'];
% PM = matfile(fn);
Diagnostics.timer_load_point_matches = toc(timer_load_point_matches);
disp(' ..... done!');diary off;diary on;

%%%%%%%%%%% Deprecated
%%     disp('** STEP 2:  Load point-matches ....');
% %     disp(' ... predict sequence of PM requests to match sequence required for matrix A');
% %     sID_all = {};
% %     fac = [];
% %     ismontage = [];
% %     count  = 1;
% %     for ix = 1:numel(zu)   % loop over sections  -- can this be made parfor?
% %         %disp(['Setting up section: ' sID{ix}]);
% %         sID_all{count,1} = sID{ix};
% %         sID_all{count,2} = sID{ix};
% %         ismontage(count) = 1;
% %         fac(count) = 1;
% %         count = count + 1;
% %         for nix = 1:opts.nbrs_step:opts.nbrs   % loop over neighboring sections with step of opts.nbrs_step
% %             if (ix+nix)<=numel(zu)
% %                 %disp(['cross-layer: ' num2str(ix) ' ' sID{ix} ' -- ' num2str(nix) ' ' sID{ix+nix}]);
% %                 sID_all{count,1} = sID{ix};
% %                 sID_all{count,2} = sID{ix+nix};
% %                 ismontage(count) = 0;
% %                 fac(count) = opts.xs_weight/(nix+1);
% %                 count = count + 1;
% %             end
% %         end
% %     end
% %     % clear sID
% %     % % perform pm requests
% %     disp('Loading point-matches from point-match database ....');
% %     wopts = weboptions;
% %     wopts.Timeout = 20;
% %     M   = {};
% %     adj = {};
% %     W   = {};
% %     np = {};  % store a vector with number of points in point-matches (so we don't need to loop again later)
% %     parfor ix = 1:size(sID_all,1)   % loop over sections
% %         %disp([sID_all{ix,1}{1} ' ' sID_all{ix,2}{1} ' ' num2str(ismontage(ix))]);
% %         if ismontage(ix)
% %             [m, a, w, n] = load_montage_pm(pm, sID_all{ix,1}, map_id,...
% %                 opts.min_points, opts.max_points, wopts);
% %         else
% %             [m, a, w, n] = load_cross_section_pm(pm, sID_all{ix,1}, sID_all{ix,2}, ...
% %                 map_id, opts.min_points, opts.max_points, wopts, fac(ix));
% %         end
% %         M(ix) = {m};
% %         adj(ix) = {a};
% %         W(ix) = {w};
% %         np(ix) = {n};
% %     end
% %     if isempty(np)
% %         error('No point-matches found');
% %     end
% %     clear sID_all
% %     disp('... concatenating point matches ...');
% %     % concatenate
% %     M = vertcat(M{:});
% %     adj = vertcat(adj{:});
% %     W   = vertcat(W{:});
% %     np  = [np{:}]';
% %     
% %     PM.M = M;
% %     PM.adj = adj;
% %     PM.W = W;
% %     PM.np = np;
% %     
% %     if opts.filter_point_matches
% %         disp('Filtering point-matches');
% %         %warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');
% %         PM = filter_pm(PM, opts.pmopts);
% %     end
% %     
% %     if opts.use_peg
% %         %% generate new point-match entries to connect all tiles -- may not work for massive data yet
% %         tvalid = unique(PM.adj(:));  % lists all tiles that have connections to other tiles through point-matches
% %         if ~isempty(tvalid)
% %             M = cell(numel(tvalid),2);
% %             Weights = cell(numel(tvalid),1);
% %             adj = zeros(numel(tvalid),2);
% %             largetileix = ntiles + 1;   % linear index of fictitious tile
% %             np = zeros(1, numel(tvalid));
% %             % we need to get width and height information about all tvalid tile
% %             % we are assuming all tiles have same width and height here
% %             urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s', ...
% %                 rc.baseURL, rc.owner, rc.project, rc.stack, tIds{tvalid(1)});
% %             j = webread(urlChar);
% %             W = j.width;
% %             H = j.height;
% %             for ix = 1:numel(tvalid)  % loop over tiles that are registered as having point-matches to other tiles
% %                 tix = tvalid(ix);
% %                 bb = [0 0 1;W 0 1;0 H 1;W H 1];  % base is 4 corner points
% %                 aa = [rand(opts.peg_npoints-4,1)*W rand(opts.peg_npoints-4,1)...
% %                     *H ones(opts.peg_npoints-4,1)]; % add additional point to top up to n
% %                 bo = [aa;bb];
% %                 tform = [T(tix,1) T(tix,4) 0; T(tix,2) T(tix,5) 0;T(tix,3) T(tix,6) 1];
% %                 p = bo*tform;
% %                 pt = p(:,1:2);
% %                 M{ix,1} = bo(:,[1 2]);
% %                 M{ix,2} = pt;
% %                 adj(ix,:) = [tix largetileix];
% %                 np(ix) = opts.peg_npoints;
% %                 Weights{ix} = ones(1,opts.peg_npoints) * opts.peg_weight ;
% %             end
% %             PM.M = [PM.M;M];
% %             PM.adj = [PM.adj;adj];
% %             PM.W = [PM.W;Weights];
% %             PM.np = [PM.np;np'];
% %         end
% %         T(end+1,:) = [1 0 0 1 0 0];   % add the fictitious tile
% %         tIds(end+1) = {'-8888'};
% %         ntiles = ntiles + 1;
% %         ncoeff = ncoeff + tdim;
% %     end
% %     
% %     M = PM.M;
% %     adj = PM.adj;
% %     W = PM.W;
% %     np = PM.np;
% %     % cd(dir_scratch)
% %     % save PM M adj W -v7.3;
% %     % fn = [dir_scratch '/PM.mat'];
% %     % PM = matfile(fn);
% %     
% %     disp(' ..... done!');diary off;diary on;
    %% Step 3: generate row slabs of matrix A
    %%%%% Experimental: set xy to zero (after having added fictitious tile is using peg.
    if opts.transfac<1.0  % then set x and y to 0,0 for each tile
        % it is assumed in this case that translation has more freedom than other parameters
        % typical case: keep everything rigid (high lambda) and really low opts.transfac
        disp(['--- Warning: Setting all x and y to zero for starting vector']);
        T(:,3) = 0;
        T(:,6) = 0;
    end
    %%%%%%%%%%%%%%%%%%
    
    disp('** STEP 3:    Generating system matrix .... ');
    split = opts.distribute_A;
    
    npm = size(np,1);
    %disp(' .... determine row positions of point-pairs (needed for generation of A)...');
    n = 2*sum(np);
    r_sum_vec = [1;cumsum(2*np(1:npm-1))+1];
    pm_per_worker = round(npm/split);
    %disp([' .... pm_per_worker=' num2str(pm_per_worker)]);
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
    
    
    %disp(' .... export temporary files split_PM_*.mat...');%-----------------------
    fn_split = cell(split,1);
    for ix = 1:split
        fn_split{ix} = [dir_scratch '/split_PM_' num2str(nfirst)...
            '_' num2str(nlast) '_'...
            num2str(randi(10000000)) '_' num2str(ix) '.mat'];
        vec = r(ix,1):r(ix,2);
        m = M(vec,:);
        a = adj(vec,:);
        ww = W(vec);
        save(fn_split{ix}, 'm', 'a', 'ww');
    end
    clear M adj W
    diary off;diary on;
    
    
    %disp(' .... generate matrix slabs');%-----------------------
    degree = opts.degree;
    I = {};
    J = {};
    S = {};
    w = {};
    parfor ix = 1:split
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
    %disp('.... collect: generate the sparse matrix from I, J and S');
    I1 = cell2mat(I(:));clear I;
    J1 = cell2mat(J(:));clear J;
    S1 = cell2mat(S(:));clear S;
    Ib1 = cell2mat(Ib(:));clear Ib;
    Sb1 = cell2mat(Sb(:));clear Sb;
    disp('..... done!');
    %% save intermediate state
    %     disp('Saving state...');
    %     save temp;
    %     disp('... done!');
    %% Step 4: Solve
    
    disp('** STEP 4:   Solving ....'); diary off;diary on;
    %disp('Translation only system build');
    % build system and solve it
    A = sparse(I1,J1,S1, n,ntiles*tdim); clear I1 J1 S1;
    w = cell2mat(w(:));
    Wmx = spdiags(w,0,size(A,1),size(A,1));
    clear w;
    b = sparse(Ib1,ones(length(Ib1),1), double(Sb1),n,1);
    A(:,1:2) = [];
    K   = A' * Wmx * A;
    Lm  = A' * Wmx * b;
    [x2, R] = solve_AxB(K,Lm, opts, []);
    precision = norm(K*x2-Lm)/norm(Lm);
    disp(['Precision: ' num2str(precision)]);
    err = norm(A*x2-b);
    disp(['Error norm(Ax-b): ' num2str(err)]);
    Error = err;
    
    

Diagnostics.nnz_A = nnz(A);
Diagnostics.nnz_K = nnz(K);
Diagnostics.precision = precision;
Diagnostics.err = err;
Diagnostics.dim_A = size(A);
% estimate error per tile before solution (i.e. use transformation parameters from rc --- the source collection)
Diagnostics.res_o = [ 0;0;A*T(9:3:end)'-b]; % T is the source transformation parameters
[Diagnostics.tile_err_o, Diagnostics.rms_o] = system_solve_helper_tile_based_point_pair_errors(PM, Diagnostics.res_o, ntiles);

% estimate error after solution (i.e. use x2)
Diagnostics.res =  [0 ; 0; A*x2-b];
[Diagnostics.tile_err, Diagnostics.rms] = system_solve_helper_tile_based_point_pair_errors(PM, Diagnostics.res, ntiles);




%     x2 = [T(1,[3]); T(1,[6]); x2];
    x2 = [0;0;x2];
    Translation_parms = reshape(x2, tdim, ncoeff/tdim)';% remember the transformations
    Tout = T;
    Tout(:,3) = Translation_parms(:,1);
    Tout(:,6) = Translation_parms(:,2);
    

    %%
    clear x2;
    clear K Lm d tb A b Wmx tB
    disp('.... done!');
    %% ingest into Renderer
system_solve_helper_ingest_into_renderer_database(rc, rcout, ...
    Tout, tIds, z_val, opts, zu);
    
end
