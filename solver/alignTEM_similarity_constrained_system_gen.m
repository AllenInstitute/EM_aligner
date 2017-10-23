function [d, D, K, Lm, f] = alignTEM_similarity_constrained_system_gen(L, options,tdim, ncoeff)
% Generate  d (the constraints vector -- i.e. the values that are regularized against) in the second term of Eq. 1 in the notes
% based on similarity-constrained fitting.
% First we generate the matrices D and f and solve the Dm-f system as in
% Eq.3 in the notes.
% then we construct d from the values in m trivially, and construct B as in
% Eq.4 in the notes.
% In principle we are solving the whole system under similarity constraints
% this is why this function looks similar to the parent function where we
% generate A and b
% Author: Khaled Khairy Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%tdim = (options.pdegree + 1) * (options.pdegree + 2)/2; % number of coefficients for a particular polynomial
%tdim = tdim * 2;        % because we have two dimensions, u and v.
lidfix = options.lidfix;% 1;      % lidfix is the layer in which one tile will be fixed

%% determine the tile to fix
if options.tfix
    tfix = options.tfix;
else
    pvec = zeros(numel(L(lidfix).tiles),1);
    if strcmp(class(L(lidfix).pm.M{1}), 'SURFPoints'),
        using_SURF_points = 1;
    else
        using_SURF_points = 0;
    end
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
    %tfix = numel(L(lidfix).tiles); %disp('sosi --------- fixing last tile');
    tfix = find(pvec==max(pvec),1);%tfix = tfix(1);
end

%tfix = max(L(lidfix).pm.adj(:));

%% construct sub-matrices for montage
D_i = cell(numel(L),1);
f_i = cell(numel(L),1);
w_i = cell(numel(L),1);
tf_i = cell(numel(L),1);
for ix = 1:numel(L)
    [D_i{ix}, f_i{ix}, w_i{ix}, tf_i{ix}] = alignTEM_similarity_montage(...
        L(ix).pm, ...
        ix == lidfix, ... %L(ix).z==lidfix,...    % equals one if this is the layer with the fixed tile
        tfix);
end

% construct sub-matrices for cross-layer
% D_ij = cell(numel(P), 2);
% f_ij = cell(numel(P), 1);
% for ix = 1:numel(P)
%     ntiles1 = max(L(ix).pm.adj(:,1));
%     ntiles2 = max(L(ix+1).pm.adj(:,2));
%     disp([ntiles1 ntiles2]);
%     if P{ix}.id1==lfix
%         [D_ij{ix,1}, D_ij{ix,2}, f_ij{ix}] = alignTEM_similarity_crosslayer(P{ix}.M, P{ix}.adj, tf_i{lidfix},ntiles1, ntiles2, 1);
%     elseif P{ix}.id2==lfix
%         [D_ij{ix,1}, D_ij{ix,2}, f_ij{ix}] = alignTEM_similarity_crosslayer(P{ix}.M, P{ix}.adj, tf_i{lidfix},ntiles1, ntiles2, 2);
%     else
%         [D_ij{ix,1}, D_ij{ix,2}, f_ij{ix}] = alignTEM_similarity_crosslayer(P{ix}.M, P{ix}.adj, [],ntiles1,ntiles2, []);
%     end
%     disp(['-- Actual number of rows  in this block n*btdim: ' num2str(size(D_ij{ix,1},1))]);
%     disp(['-- Actual number of columns  in block 1 m1: ' num2str(size(D_ij{ix,1},2))]);
%     disp(['-- Actual number of columns  in block 2 m2: ' num2str(size(D_ij{ix,2},2))]);
% end
% nP = numel(P);
% cleanup
%clear P

%% assemble the full matrix D and vector f
n = 0;
m = 0;
% preallocate memory for I J S, we need to know their size
sz = 0;
for ix = 1:numel(D_i), % for the montages
    n = n + size(D_i{ix},1);
    m = m + size(D_i{ix},2);
    sz = sz + nnz(D_i{ix});
end
% if nP>0 %~isempty(P)
%     for ix = 1:numel(D_ij,1), % for crosslayer
%         n = n+size(D_ij{ix},1);
%         %%%%%m = m + size(A_ij{ix},2);
%         sz = sz + nnz(D_ij{ix,1});
%         sz = sz + nnz(D_ij{ix,2});
%     end
% end
if options.verbose,
    disp(' ---------------------------------------------');
    disp(['Consistency test: Size of D is projected to be: ' ...
        num2str(n) ' x ' num2str(m) '.']);
    disp(['Total number of elements is projected to be: ' ...
        num2str(sz)]);
    disp('Constructing large matrix D and vector f');
end
f = sparse(n,1);
dW = ones(n,1);
n = 0;
m = 0;
I = zeros(sz,1);
J = zeros(sz,1);
S = zeros(sz,1);
pos = 0;
verbose =   0;
for ix = 1:numel(D_i),
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  montage matrices
        if verbose,
            disp(['Placing  block D_' num2str(ix) ' of size ' ...
            num2str(size(D_i{ix})) ' at ' num2str([n m]+1)]);
        end
    [I(pos+1:pos+nnz(D_i{ix})),...
        J(pos+1:pos+nnz(D_i{ix})),...
        S(pos+1:pos+nnz(D_i{ix}))] = find(D_i{ix});
    
    % place this matrix in the correct block location
    I(pos+1:pos+nnz(D_i{ix})) = I(pos+1:pos+nnz(D_i{ix})) + n; % row location
    J(pos+1:pos+nnz(D_i{ix})) = J(pos+1:pos+nnz(D_i{ix})) + m; % column location
    pos = pos + nnz(D_i{ix});
    

    % update the weights vector
    dW(n+1:n+size(D_i{ix},1)) = w_i{ix};
    
    % update vector f
    f(n+1:n+size(D_i{ix},1)) = f_i{ix};
    
    % update dimensionality of D
    n = n+size(D_i{ix}, 1);
    m_old = m;
    m = m+size(D_i{ix},2); % only increases (horizontally)
    % as new layers are added
    
    if verbose
        disp('--- placing montage block');
        disp(ix);
        disp(['---------- max J: ' num2str(max(J))]);
        disp(['---------- m    : ' num2str(m)]);
    end

end
% cleanup
%disp('Cleanup: D_i D_ij f_ij');
%clear D_i D_ij f_ij;


%%
D = sparse(I,J,S,n,m);
spD = nnz(D)/(size(D,1))/size(D,2) * 100;
if options.verbose, disp(['Sparsity of D in percent: ' num2str(spD)]);end
W = sparse(1:n, 1:n, dW, n, n);
% cleanup
clear I J S;
%% %%%%% solve for m
% m = D\f;
K = D'*W*D;
Lm = D'*W*f;
%m = solve_AxB(D,f,options,[]);
m = solve_AxB(K,Lm,options,[]);
%% %%%%% Construct the vector d and matrix B
dtdim = 4;
% ncoeff = size(D,2)/dtdim * tdim;
d = zeros(ncoeff,1);
% td = zeros(ncoeff,1);

if options.verbose, disp('Populating vector d');end
pos = 0;
mpos = 0;
for lix = 1:numel(L)
    if options.verbose, disp(['Adding vector d elements for layer: ' num2str(lix)]);end
    for tix = 1:numel(L(lix).tiles)
        if ~(lix == lidfix && tix==tfix)
            % i.e. if the current tile is not the fixed tile
            st = m(mpos+1:mpos + dtdim);
            if tdim==6
                d(pos+1:pos+tdim) = [st(1) st(2) 0 st(3) st(4) 0];
                %td(pos+1:pos+tdim) = [st(1) st(2) options.translation_fac st(3) st(4) options.translation_fac];
            elseif tdim==12
                d(pos+1:pos+tdim) = [0 st(1) st(2) 0 0 0 0 st(3) st(4) 0 0 0];
                %d(pos+1:pos+tdim) = [t(3) t(1) t(2) 0 0 0 t(6) t(4) t(5) 0 0 0];
            elseif tdim==20
                d(pos+1:pos+tdim) = [0 st(1) st(2) 0 0 0 0 st(3) st(4) 0 0 0 zeros(1,8)];
                %d(pos+1:pos+tdim) = [t(3) t(1) t(2) 0 0 0 t(6) t(4) t(5) 0 0 0 zeros(1,8)];
            end
            pos = pos + tdim;
            mpos = mpos + dtdim;
        else
            if options.verbose, disp(['fixed tile skipped in d is: ' num2str([lix tfix])]);end
            fac = -1;
            if tdim==6
                d(pos+1:pos+tdim) = [fac*1 0 0 0 fac*1 0];
                %td(pos+1:pos+tdim) = [fac*1 0 options.translation_fac 0 fac*1 options.translation_fac];
            elseif tdim==12
                d(pos+1:pos+tdim) = [0 st(1) st(2) 0 0 0 0 st(3) st(4) 0 0 0];
                %d(pos+1:pos+tdim) = [t(3) t(1) t(2) 0 0 0 t(6) t(4) t(5) 0 0 0];
            elseif tdim==20
                d(pos+1:pos+tdim) = [0 st(1) st(2) 0 0 0 0 st(3) st(4) 0 0 0 zeros(1,8)];
                %d(pos+1:pos+tdim) = [t(3) t(1) t(2) 0 0 0 t(6) t(4) t(5) 0 0 0 zeros(1,8)];
            end
            pos = pos + tdim;
        end
    end
end

% disp('Constructing matrix B');
% disp(['Using translation factor: 0']);% num2str(options.translation_fac)]);
% Bd = ones(ncoeff,1);
% B = sparse(1:ncoeff, 1:ncoeff, Bd, ncoeff, ncoeff);

% tBd = ones(ncoeff,1);
% if tdim ==6
%     tBd(3:3:end) = options.translation_fac;% options.translation_fac;% 0 = do not constrain translation
% elseif tdim==12
%     tBd(1:6:end) = options.translation_fac;
% elseif tdim==20
%     tBd(1:10:end) = options.translation_fac;
% end
% tB = sparse(1:ncoeff, 1:ncoeff, tBd, ncoeff, ncoeff);









































