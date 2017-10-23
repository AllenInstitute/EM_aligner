function [L,err,R, A, b, B, d, W, K, Lm, xout, iL2, iU2, tB, td, invalid,...
         toc_Axb, toc_gen_A] = ...
        alignTEM_solver(L, P, options)
%% works as is, but needs  refactoring because: 
% [1] we don't use P anymore and 
% [2] all tiles are expected to be in L (which is not an array)
% [3] we should not even need L, but 
% [4] should be able to solve given point-matches for a connected component
%       in case of no regularization, and any other set if regularized
% [5] We need to express constraints in a flexible way.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Purpose: solve for transformation coefficients using the set of point-matches.
%%%          All point match information is contained in L
%%%
%%% Input: L, P(obsolete) and options
%%% L is an array (obsolete) of Msection objects with the field "pm"
%%% being a struct (for each Msection object) that has the fields M
%%% and adj, that specify blocks of point correspondences (M) and the
%%% adjacency indices for tiles (adj)
%%% P (obsolete) is a cell array of Msection pair information. Each entry contains M
%%% and adj, similar to above, except that adj(:,1) (and also M{:,1}) are
%%% specifice to the lower of the two layers.
%%% Example P{1} for two the case of two layers, i.e. there is only one pair and P is a
%%% cell array with one element, which is for example the struct:
%%% M: {5810x2 cell}
%%%     adj: [5810x2 double]
%%%     id1: 2336
%%%     id2: 2337
%%% Example options struct:
%%%
%%% lsq_options.verbose = 1;
%%% lsq_options.lambda = 1e5;
%%% lsq_options.nmax = inf;
%%% lsq_options.var_cross = 1e0;
%%% lsq_options.var_in = 1e0;
%%%
%%% options.constraints = 'alignBK': alignBK guess is already given in the tile transformations
%%% OR: if options.constraints=="similarity" ---> calculate a similarity,constraint guess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Author: Khaled Khairy 2014 Janelia

% if numel(P) + 1 ~= numel(L),
%     error('Please check dimensions of L and P inputs');
% end
toc_Axb = 0;
toc_gen_A = 0;
A   = [];
b   = [];
B   = [];
d   = [];
R = [];
W = [];
K = [];
Lm = [];

err = [];
iL2 = [];
iU2 = [];
tB = [];
td = [];
%%%%%%%%%% Configuration
if options.verbose, disp(options);end
if isfield(options, 'lambda');
lambda = options.lambda;
else
    lambda = 1;
end
if ~isfield(options, 'matrix_only')options.matrix_only = 0;end

%nmax = options.nmax;
tdim = (options.pdegree + 1) * (options.pdegree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
lidfix = options.lidfix;  % just choose one layer (linear index) with a tile to be fixed
tfix   = options.tfix;
ncoeff = 0;
for lix = 1:numel(L)
    ncoeff = ncoeff + numel(L(lix).tiles)*tdim;
end
%% Determine tile to fix
% tfix = 0;
if lidfix && ~options.tfix==0
    tfix = options.tfix;
elseif lidfix && options.tfix==0  % then we need to find tfix
    if lidfix>numel(L), lidfix=numel(L);warning('Resetting fixed-tile section to last section');end
    if strcmp(class(L(lidfix).pm.M{1}), 'SURFPoints'),
        using_SURF_points = 1;
    else
        using_SURF_points = 0;
    end
    %    disp('Determining candidate tile to fix');
    pvec = zeros(numel(L(lidfix).tiles),1);
    for tix = 1:numel(L(lidfix).tiles)
        ind = find(L(lidfix).pm.adj(:,1)==tix);
        ind = [ind; find(L(lidfix).pm.adj(:,2)==tix)];
        for ix = 1:numel(ind)
            if using_SURF_points
                pvec(tix) = pvec(tix) + numel(L(lidfix).pm.M{ind(ix), 1}.Location);
            else
                pvec(tix) = pvec(tix) + numel(L(lidfix).pm.M{ind(ix), 1});
            end
        end
    end
    tfix = find(pvec==max(pvec),1);%tfix = tfix(1);
end
 % translate the complete system relative to this tile
if lidfix % && options.tfix==0
    dx = L(lidfix).tiles(tfix).tform.T(3);
    dy = L(lidfix).tiles(tfix).tform.T(6);
    for lix = 1:numel(L)
        %
        for tix = 1:numel(L(lix).tiles)
            L(lix).tiles(tix).tform.T(3) =  L(lix).tiles(tix).tform.T(3) - dx;
            L(lix).tiles(tix).tform.T(6) =  L(lix).tiles(tix).tform.T(6) - dy;
        end

    end
end
sf = [1 1];

%% %%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT B AND d %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(options.B)
    if strcmp(options.constraint, 'explicit')
        if options.verbose,disp('---------------- Constraint system based on explicit constraints (maybe previous solver solution) -------');end
        if isempty(options.d)
        [B,d, tB, td] = alignTEM_explicit_constrained_system_gen(L,options, tdim, ncoeff, sf);
        else
            disp('reusing input stvec information');
        end
        %warning('Explicit constraints do not allow fixing tiles');
        %lidfix = 0;
        %tfix = 0;
        if (lidfix && tfix)
            ixrange = (tdim*(tfix-1)+1):(tdim*(tfix-1) + tdim);
            td(ixrange) = [];
            d(ixrange) = [];
            tB(ixrange, :) = [];
            tB(:,ixrange) = [];
        end
    elseif strcmp(options.constraint, 'similarity')
        if options.verbose,disp('---------------- Similarity constrained system ------------------');end
        [d, Ds, Ks, Lms, fs] = alignTEM_similarity_constrained_system_gen(L, options,tdim, ncoeff);
        lidfix = 0;
        tfix = 0;
        options.constraint_only = 1;
        if options.verbose,
            disp('-------------------------------------------');
            disp('-- setting options to "constraints only" --');
            disp('-------------------------------------------');
        end
    elseif strcmp(options.constraint, 'trivial')
        if options.verbose,disp('---------------- Generating constraint system based on trivial transform -------------');end
        [B, d, tB, td] = alignTEM_trivial_constrained_system_gen(L,lidfix, tfix, options, tdim, ncoeff, sf);
    elseif strcmp(options.constraint, 'none')
        B = [];
        d = [];
        td = sparse(ncoeff-tdim,1);
        tB = sparse(ncoeff-tdim, ncoeff-tdim);
        lambda = 0;
        if options.verbose,
            disp('--------------------');
            disp('-- no constraints --');
            disp('--------------------');
        end
        options.constraint_only = 0;
    end
end
if options.constraint_only 
    x2 = d;
    A = Ds;
    K = Ks;
    Lm = Lms;
    d = fs;
   
else
    %% %%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT A AND b %%%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(options.A)
        disp('--------------------------------');
        disp('constructing matrix A ..........');
        kk_clock;
        tic_gen_A = tic;
        [A,b, W] = alignTEM_objective_system_gen(L,P, lidfix, tfix, options, sf);
        toc_gen_A = toc(tic_gen_A);
        kk_clock;
        disp('... done!');
        disp('--------------------------------');
    else
        disp('reusing input matrix A');
        A = options.A;
        b = options.b;
        W = options.W;
        
    end
    
    %% construct final matrices
    if options.verbose
        disp('Solve constrained system');
        disp(['Using lambda: ' num2str(lambda)]);
        disp(['Constructing K and Lm for the method of normal equations']);
    end
    
    %% determine edge tiles if required
    if options.edge_lambda==options.lambda,
        options.constrain_edges=0;
    end
    if options.constrain_edges
        if isempty(L(lix).edge_tiles)
            disp('Finding edge tiles ...');
            % split into z and determine edges for each z
            ll = split_z(L(lix));
            etix = [];
            for lix = 1:numel(ll)
                ll(lix).edge_tiles = get_edge_tiles(ll(lix));
                etix = [etix; ll(lix).edge_tiles];  % assumes that field edge_tiles has been updated
            end
            %L(lix).edge_tiles = get_edge_tiles(L(lix));
            disp('Done!');
            %warning('No edge tiles found --- calculating');
        end
        if options.verbose,disp('------------ Using edge constraints');end
        fac_inner = 1;
        %etix = [sum(L.A,2)<4]'; % logical vector of edge tiles
%         etix = [];
%         for lix = 1:numel(L)
%             etix = [etix; L(lix).edge_tiles];  % assumes that field edge_tiles has been updated
%         end
         etix = etix';
         etix = etix*options.edge_lambda ;   % edge tiles get extra constraint
         etix(etix==0) = fac_inner; % inner tiles get a value typically 1
         etix = etix(ones(tdim,1), :);
         etix = etix(:);
        tB(1:size(tB,1)+1:end) = diag(tB).*etix;
        td = td.*etix;

    end
    %% %%%%%%%%%%%%%%%%%%%%%%%%%% solve  %%%%%%%%%%%%%%%%%%%%%%%%%
    % generate K and Lm, the SPD system that actually gets solved
    if strcmp(options.solver,'backslash--noreg')
        if options.verbose,disp('------------ Performing backslash -- no reg');end
        K = A;
        Lm = b;
    else
        K  = A'*W*A + lambda*(tB')*tB;
        Lm  = A'*W*b + lambda*(tB')*td;
    end
    spK = 1- nnz(K)/prod(size(K)); %#ok<PSIZE>
    if options.verbose,disp(['Sparsity of K: ' num2str(spK)]);end
    if options.verbose>1
        disp(['Estimated condition number of K: ' num2str(condest(K))]); disp(condest(K));
        disp('Ranges min max:');
        disp(['A : ' num2str([min(A(:)) max(A(:))])]);
        disp(['b : ' num2str([min(b(:)) max(b(:))])]);
        disp(['W : ' num2str([min(W(:)) max(W(:))])]);
        disp(['B : ' num2str([min(B(:)) max(B(:))])]);
        disp(['d : ' num2str([min(d(:)) max(d(:))])]);
        disp(['K : ' num2str([min(K(:)) max(K(:))])]);
        disp(['Lm : ' num2str([min(Lm(:)) max(Lm(:))])]);
    end
    
    % K  = A'*A + lambda*(B')*B;
    % Lm  = A'*b  + lambda*(B')*d;
    %disp('Clearing memory: deleting A W B b');
    % cleanup
    %clear A W B b
    
    
    % % Solve
    if options.matrix_only==0

    [x2, R, toc_Axb] = solve_AxB(K,Lm, options, d);

    else
        disp('option.matrix_only is non-zero, not solving. Returning starting vector as solution');
        x2 = d;
    end
    if strcmp(options.constraint, 'explicit')
       err = norm(A*x2-b);%/norm(A*d-b);
    end
end
xout = x2;
x2 = full(x2);



if options.verbose,
    if sum(isnan(x2(:)))
        if options.verbose,
            disp(['Possible invalid result. nan detected entries affected --> ' num2str(sum(isnan(x2(:))))]);
            disp(['percent entries in solution vector affected --> ' num2str(sum(isnan(x2(:)))/(numel(x2(:))) * 100)]);
        end
    end
end

%%
if options.verbose,disp('Generate the final array of refined transformations');end
if lidfix && tfix
    T = reshape(x2, tdim, (ncoeff-tdim)/tdim)';% remember, the transformations
else
    T = reshape(x2, tdim, ncoeff/tdim)';% remember, the transformations
end
% insert the trivial transformation for the fixed tile (if a tile was fixed)
if lidfix
    %x2(isnan(x2))= 0;
    % x2(3:6:end) = x2(3:6:end) * Tfacx;
    % x2(6:6:end) = x2(6:6:end) * Tfacy;
    % % generate array of transformations
    
    % % Determine transformation for fixed tile
    if tdim==2
       To = L(lidfix).tiles(tfix).tform.T([3 6]); 
    elseif tdim == 6
        To = L(lidfix).tiles(tfix).tform.T([1:6]); 
    elseif tdim ==12
        To = [0 1 0 0 0 0 0 0 1 0 0 0];
    elseif tdim ==20
        To = [0 1 0 0 0 0 0 0 1 0 0 0 zeros(1,8)];
    end
    % insert the trivial transformation for the fixed tile
    %tfix = tf_i{lidfix};
    % determine position of the tile in T
    ntiles_before = numel([L(1:lidfix-1).tiles]);
    pos = ntiles_before + tfix;
    
    
    % % % fix the signs just in case everything was rotated
    % if tdim==6
    %     To(1) = To(1) * sign(T(1));
    %     To(5) = To(5) * sign(T(1,5));
    % elseif tdim==12
    %     To(2) = To(2) * sign(T(1,2));
    %     To(9) = To(9) * sign(T(1,9));
    % elseif tdim==20
    %     To(2) = To(2) * sign(T(1,2));
    %     To(9) = To(9) * sign(T(1,9));
    % end
    
    if pos==1,
        T = [To(:)'; T(1:end,:)];
    else
        T = [T(1:pos-1,:); To(:)'; T(pos:end,:)];
    end
%     % compare to initial guess
%     if options.verbose,
%         disp(num2str(L(lidfix).tiles(1).tform.T(:)'));
%         disp(num2str(T(ntiles_before + 1,:)));
%     end
end
%% update transformations
if options.verbose,disp('Updating transformations');end
counter = 1;
n_invalid = 0;
invalid = [];
%L2 = L;
for lix = 1:numel(L)
    for tix = 1:numel(L(lix).tiles)
        if any(isinf(T(counter,:))) ||...
                any(isnan(T(counter,:)))
            if options.verbose,disp(['Invalid transformation. Eliminating tile:layer/tileidx/tileid: ' num2str([lix tix L(lix).tiles(tix).id])]);end
            n_invalid = n_invalid + 1;
            L(lix).tiles(tix).state = 0;
        else
            if tdim==2
                L(lix).tiles(tix).tform.T([3 6]) = T(counter,:);
            elseif tdim==6
                if ~issingular(T(counter,:))
                    L(lix).tiles(tix).tform.T(1:6) = T(counter,:);
                else
%                     warning(['Singular transformation matrix detected: ' num2str(tix) ' section ' num2str(lix)]);
%                     disp(['Transformation matrix unchanged for section/tile:  ' num2str(lix) ' / ' num2str(tix) ]);
%                     disp('tile state degraded to -2');
%                     disp(num2str(T(counter,:)));
%                     disp('------------------------------------------------------');
                    L(lix).tiles(tix).state = -2;
                    n_invalid = n_invalid + 1;
                    invalid = [invalid;lix tix];
                end
            elseif tdim==12
                tform = images.geotrans.PolynomialTransformation2D(T(counter,1:6),T(counter,7:12));
                L(lix).tiles(tix).tform = tform;
            elseif tdim==20
                tform = images.geotrans.PolynomialTransformation2D(T(counter,1:10),T(counter,11:20));
                L(lix).tiles(tix).tform = tform;
            end
            
        end
        counter = counter + 1;
    end
    %L2 = L(lix);
    %     if options.verbose,disp(['Filtering layer: ' num2str(lix)]);end
    %     %L(lix) = filter_based_on_tile_area(L(lix));
    %     [L(lix), Areas, Perims, delvec] = detect_spurious_tiles(L(lix)); % some tiles are deformed too much
    %     L(lix).tiles(delvec) = [];
    %     disp('sosi: retaining largest cluster on a per layer basis --- needs to change to whole stack');
    %     if options.largest_cluster
    %         % % % cluster analysis
    %         L(lix) = reduce_section_to_largest_cluster(L(lix)); % just take the largest chunck
    %     end
end
if options.verbose,disp(['Number of invalid/singular transformations (tiles): ' num2str(n_invalid)]);end


%% 
function r = issingular(m)
tol = 1e-20;
m = m([1 2 4 5]);
d = det(reshape(m, 2,2));
r = 0;
if d<tol, r = 1;end





