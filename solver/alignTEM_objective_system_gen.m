function [A,b,W] = alignTEM_objective_system_gen(L,P, lidfix, tfix, options, sf)
%% %%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT A AND b %%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'var_cross')
var_cross = options.var_cross;
var_in = options.var_in;
else
    var_cross = 1;
    var_in = 1;
end
if lidfix
    lfix = L(lidfix).z;      % lfix is the section id for the layer in which one tile will be fixed
else
    lfix = 0;
end
%construct sub-matrices for montage
A_i = cell(numel(L),1);
b_i = cell(numel(L),1);
w_i = cell(numel(L),1);
tf_i = cell(numel(L),1);
pdegree = options.pdegree;
disp('Generating matrix A blocks ...');
tic
for ix = 1:numel(L)
    ntiles = numel(L(ix).tiles);
    [A_i{ix}, b_i{ix},w_i{ix}, tf_i{ix}] = alignTEM_objective_montage(...
        L(ix).pm, ...
        L(ix).z==lfix,...    % equals one if this is the layer with the fixed tile
        tfix, ...
        pdegree, sf, ntiles);
end
toc;
disp('Done');

% construct sub-matrices for cross-layer
% A_ij = cell(numel(P), 2);
% b_ij = cell(numel(P), 1);
% for ix = 1:numel(P)
%     if P{ix}.id1==lfix
%         [A_ij{ix,1}, A_ij{ix,2}, b_ij{ix}] = alignTEM_objective_cross(P{ix}.M, P{ix}.adj, tf_i{lidfix}, 1, options.pdegree,sf);
%     elseif P{ix}.id2==lfix
%         [A_ij{ix,1}, A_ij{ix,2}, b_ij{ix}] = alignTEM_objective_cross(P{ix}.M, P{ix}.adj, tf_i{lidfix}, 2, options.pdegree,sf);
%     else
%         [A_ij{ix,1}, A_ij{ix,2}, b_ij{ix}] = alignTEM_objective_cross(P{ix}.M, P{ix}.adj, [], [], options.pdegree, sf);
%     end
% end
% nP = numel(P);
% cleanup
%clear P

% % assemble the full matrix A, vector b and weights matrix W
n = 0;
m = 0;
% preallocate memory for I J S, we need to know their size
disp('Preallocating memory for final sparse matrix vectors');
tic
sz = 0;
for ix = 1:numel(A_i), % for the montages
    n = n + size(A_i{ix},1);
    m = m + size(A_i{ix},2);
    sz = sz + nnz(A_i{ix});
end
% if nP>0 %~isempty(P)
%     for ix = 1:numel(A_ij,1), % for crosslayer
%         n = n+size(A_ij{ix},1);
%         %%%%%m = m + size(A_ij{ix},2);
%         sz = sz + nnz(A_ij{ix,1});
%         sz = sz + nnz(A_ij{ix,2});
%     end
% end
if options.verbose,
    disp(' ---------------------------------------------');
    disp(['Consistency test: Size of A is projected to be: ' ...
        num2str(n) ' x ' num2str(m) '.']);
    disp(['Total number of elements is projected to be: ' ...
        num2str(sz)]);
    disp('Constructing large matrix A, vector b and matrix W');
end
dW = ones(n,1);
if lfix
    b = zeros(n,1);
else
    b = sparse(n,1);
end
n = 0;
m = 0;
I = zeros(sz,1);
J = zeros(sz,1);
S = zeros(sz,1);
pos = 0;
toc;

for ix = 1:numel(A_i),
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     %%%% montage matrices
    %         if options.verbose,
    %             disp(['Placing  block A_' num2str(ix) ' of size ' ...
    %             num2str(size(A_i{ix})) ' at ' num2str([n m]+1)]);
    %         end
    nnzA = nnz(A_i{ix});
    [I(pos+1:pos+nnzA),...
        J(pos+1:pos+nnzA),...
        S(pos+1:pos+nnzA)] = find(A_i{ix});
    
    % place this matrix in the correct block location
    I(pos+1:pos+nnzA) = I(pos+1:pos+nnzA) + n; % row location
    J(pos+1:pos+nnzA) = J(pos+1:pos+nnzA) + m; % column location
    pos = pos + nnzA;
    
    % update vector b
    b(n+1:n+size(A_i{ix},1)) = b_i{ix};
    
    % update the weights vector
%     dW(n+1:n+size(A_i{ix},1)) = 1/var_in;
    dW(n+1:n+size(A_i{ix},1)) = w_i{ix};
    % update dimensionality of A
    n = n+size(A_i{ix}, 1);
    m_old = m;
    m = m+size(A_i{ix},2); % only increases (horizontally)
    
    %         if options.verbose,
    %             disp('Consistency check: ')
    %             disp(['block A_' num2str(ix) ' of size ' ...
    %             num2str(size(A_i{ix})) ' was added. Current dimensions ' ...
    %             num2str([n m]) ' ??==?? ' num2str([max(I) max(J)])]);
    %         end
    
    % as new layers are added
    
    % add crosslayer matrices
    % assumes that we have a crosslayer matrix coupling layer A_i{ix}
    % with A_i{ix+1}
    
    %     disp(pos)
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % add crosslayer coupling
%     if (nP)>=ix
%         %         if options.verbose,
%         %             disp(['Placing first cross block A_' num2str(ix) ' i = ' num2str(P{ix}.id1) ...
%         %                 ' j = ' num2str(P{ix}.id2) ' of size ' ...
%         %                 num2str(size(A_ij{ix,1})) ' at ' num2str([n m_old]+1)]);
%         %         end
%         % the first one of the pair
%         [I(pos+1:pos+nnz(A_ij{ix,1})),...
%             J(pos+1:pos+nnz(A_ij{ix,1})),...
%             S(pos+1:pos+nnz(A_ij{ix,1}))] = find(A_ij{ix,1});
%         
%         % place this matrix in the correct block location
%         I(pos+1:pos+nnz(A_ij{ix,1})) = I(pos+1:pos+nnz(A_ij{ix,1})) + n;
%         J(pos+1:pos+nnz(A_ij{ix,1})) = J(pos+1:pos+nnz(A_ij{ix,1})) + m_old;
%         pos = pos + nnz(A_ij{ix,1});
%         %n = n+size(A_ij{ix,1}, 1);
%         
%         %         if options.verbose,
%         %             disp(['Placing second cross block A_' num2str(ix) 'i = ' num2str(P{ix}.id1) ...
%         %                 ' j = ' num2str(P{ix}.id2) ' of size ' ...
%         %                 num2str(size(A_ij{ix,2})) ' at ' num2str([n m]+1)]);
%         %         end
%         % the second one of the pair
%         [I(pos+1:pos+nnz(A_ij{ix,2})),...
%             J(pos+1:pos+nnz(A_ij{ix,2})),...
%             S(pos+1:pos+nnz(A_ij{ix,2}))] = find(A_ij{ix,2});
%         
%         % place this matrix in the correct block location
%         I(pos+1:pos+nnz(A_ij{ix,2})) = I(pos+1:pos+nnz(A_ij{ix,2})) + n;
%         J(pos+1:pos+nnz(A_ij{ix,2})) = J(pos+1:pos+nnz(A_ij{ix,2})) + m;
%         pos = pos + nnz(A_ij{ix,2});
%         
%         % update vector b
%         b(n+1:n+size(A_ij{ix},1)) = b_ij{ix};
%         
%         % update the weights vector
%         dW(n+1:n+size(A_ij{ix},1)) = 1/var_cross;
%         % add the number of points to get the correct dimensionality of the
%         % final matrix A
%         n = n+size(A_ij{ix,2}, 1);
%     end
end
% cleanup
%disp('Cleanup: A_i A_ij b_ij');
clear A_i A_ij b_ij;
%%
if isfield(options, 'use_spmd')
if options.use_spmd
    spmd(32)
        disp(numlabs);
        codist = codistributor1d();
        SV = codistributed(S,codist);
        %dW = codistributed(dW, codist);
        b = codistributed(dW, codist);
    end
    A = sparse(I,J,SV,n,m);
    spA = nnz(A)/(size(A,1))/size(A,2) * 100;
    %disp(['Sparsity of A in percent: ' num2str(spA)]);
    W = spdiags(dW,0,size(A,1),size(A,1));
else
    %%
    A = sparse(I,J,S,n,m);
    spA = nnz(A)/(size(A,1))/size(A,2) * 100;
    %disp(['Sparsity of A in percent: ' num2str(spA)]);
    W = spdiags(dW,0,size(A,1),size(A,1));
end
else
    %%
    A = sparse(I,J,S,n,m);
    spA = nnz(A)/(size(A,1))/size(A,2) * 100;
    %disp(['Sparsity of A in percent: ' num2str(spA)]);
    W = spdiags(dW,0,size(A,1),size(A,1));
end



% cleanup
clear I J S dW;