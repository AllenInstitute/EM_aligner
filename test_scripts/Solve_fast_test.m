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
nlast  = 200;

% configure rough collection
rc.stack          = 'FUSED_ROUGH_01';
rc.owner          ='flyTEM';
rc.project        = 'test2';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

% configure fine output collection
rcout.stack          = ['EXP_FAFBv13_slab_' num2str(nfirst) '_' num2str(nlast) '_fine_pastix'];
rcout.owner          ='flyTEM';
rcout.project        = 'test2';
rcout.service_host   = '10.40.3.162:8080';
rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];
rcout.verbose        = 1;
rcout.versionNotes   = 'testing pastix for massive joint solution and distributed A generation';

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';



% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';%'pastix';%%'gmres';%'backslash';'pastix';



opts.pastix.ncpus = 8;
opts.pastix.parms_fn = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
opts.pastix.split = 1; % set to either 0 (no split) or 1

opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = '/scratch/khairyk';


opts.min_points = 3;
opts.max_points = 100;
opts.nbrs = 3;
opts.xs_weight = 0.5;
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;

opts.lambda = 10.^(-5:.5:5);
%opts.edge_lambda = 10^(-1);
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

dir_scratch = [opts.dir_scratch '/temp_' num2str(randi(3000000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);
diary on;
% obtain actual section zvalues in given range their ids and also of possible reacquires
[zu, sID, sectionId, z, ns] = get_section_ids(rc, nfirst, nlast);
% determine W and H
webopts = weboptions('Timeout', 60);
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack,zu(1));
j = webread(urlChar, webopts);
jt1 = tile(j(1));
Width = jt1.W;
Height = jt1.H;

%% Step 1: load transformations, tile ids
% load all tiles in this range and pool into Msection object
disp('Loading transformations and tile/canvas ids from Renderer database.....');
[T, map_id, tIds, z_val] = load_all_transformations(rc, zu, dir_scratch);
ntiles = size(T,1);
disp(['..system has ' num2str(ntiles) 'tiles...']);
%[L, map_id, tIds] = load_all_tiles(rc,zu);ntiles = numel(L.tiles);
degree = opts.degree;
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
ncoeff = ntiles*tdim;
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
clear sID
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
clear sID_all
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
I = {};
J = {};
S = {};
w = {};
parfor ix = 1:split
    [I{ix}, J{ix}, S{ix}, wout] = gen_A_b_row_range(fn_split{ix}, ...
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
disp('..... done!');
%% Step 4: Solve
disp('** STEP 4:   Solving ....'); diary off;diary on;
% build system and solve it
A = sparse(I1,J1,S1, n,ntiles*tdim); clear I1 J1 S1;
b = sparse(size(A,1), 1);
w = cell2mat(w(:));
Wmx = spdiags(w,0,size(A,1),size(A,1));
clear w;
d = reshape(T', ncoeff,1);clear T;
tB = ones(ncoeff,1);
tB = sparse(1:ncoeff, 1:ncoeff, tB, ncoeff, ncoeff);


%%%% determine regularization parameter if opts.lambda is a range
deformation_indx = [];
error = [];
perim_o = 2*Width + 2*Height;
for lambdaix = 1:numel(opts.lambda)
    disp(['Solving ' num2str(lambdaix) ' of ' ...
           num2str(numel(opts.lambda)) ' -- lambda: ' ...
           num2str(opts.lambda(lambdaix))]);
       
    lambda = opts.lambda(lambdaix);
    K  = A'*Wmx*A + lambda*(tB')*tB;
    Lm  = A'*Wmx*b + lambda*(tB')*d;
    [x2, R] = solve_AxB(K,Lm, opts, d);
    err = norm(A*x2-b); disp(['Error norm(Ax-b): ' num2str(err)]);
    Error(lambdaix) = err;
    Tout = reshape(x2, tdim, ncoeff/tdim)';% remember, the transformations
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% step 4': calculate deformation
    % make four corners for this tile
    x = 0;
    y = 0;
    Px = [x; x + Width; x + Width; x];
    Py = [y; y    ; y + Height; Height];
    
    parfor jix = 1:size(Tout,1)
        
        %%% transform points
        if opts.degree==1
            T = [reshape(Tout(jix,:),3,2)];
            T(3,3) = 1;
            P = [Px(:) Py(:) [1 1 1 1]']*T;
            %else
            %%% not implemented yet
        end
        % check polygon area
        Ar(jix) = polyarea(P(:,1), P(:,2));
        Aratio(jix) = Ar(jix)/(Height * Width);
        %%% polygonperimeter
        s = 0;
        s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
        s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
        s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
        s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
        S(jix) = s;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%     sig = std(S);
%     mu = mean(S);
%     fac = 3;
%     indx = [find(Aratio<(mu-fac*sig)) find(Aratio>(mu+fac*sig))];
%     Aratio(indx) = [];
    deformation_indx(lambdaix) = mean(abs(S-perim_o));
end
deformation_indx = deformation_indx/max(deformation_indx);
Error = Error/max(Error);

diffd = gradient(deformation_indx);
yyaxis left
plot(log(opts.lambda), diffd, 'go');title('Gradient of deformation');
hold on;
plot(log(opts.lambda), diffd, 'b-');
yyaxis right
plot(log(opts.lambda), Error, 'go');title('normalized error and normalized deformation');
hold on;
plot(log(opts.lambda), Error, 'k-');
hold on;
plot(log(opts.lambda), deformation_indx, 'r-');

%%% decide on lambda and proceed

lambda = opts.lambda(find(diffd == max(diffd)));
disp('--------- using lambda:');
disp(lambda);
disp('-----------------------');
K  = A'*Wmx*A + lambda*(tB')*tB;
Lm  = A'*Wmx*b + lambda*(tB')*d;
[x2, R] = solve_AxB(K,Lm, opts, d);
err = norm(A*x2-b); disp(['Error norm(Ax-b): ' num2str(err)]);
Error(lambdaix) = err;
Tout = reshape(x2, tdim, ncoeff/tdim)';% remember, the transformations
%%
clear x2;
clear K Lm d tb A b Wmx tB
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

% delete_renderer_stack(rcout);








