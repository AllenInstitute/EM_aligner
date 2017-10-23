function [D, f, w, tfix] = alignTEM_similarity_montage(pm, tfix_flag, tfix)
%%% build the regularaization term (term 2) for a montage
M   = pm.M;
adj = pm.adj;
if ~isfield(pm,'W')
    W = ones(size(adj,1));
else
    W = pm.W;
end
%% Generate matrices for the objective function (term 1).
if strcmp(class(M{1}), 'SURFPoints'),
    using_SURF_points = 1;
else
    using_SURF_points = 0;
end

ntiles = max(adj(:));

if ntiles<tfix, tfix = ntiles;end
%% determine number of point-pairs for preallocation
np_vec = zeros(size(M,1),1);
for ix = 1:size(M,1)
    if using_SURF_points
        np_vec(ix) = size([M{ix,1}.Location],1);
    else
        np_vec(ix) = size([M{ix,1}],1);
    end
end
n = 2*sum(np_vec);
%% calculate B and d
btdim = 4;
bm = btdim * ntiles;%max(adj(:));
% % B = sparse(2*n,bm);
f = sparse(2*n,1);
w = zeros(2*n,1);

I = zeros(2*n*btdim,1);
J = zeros(2*n*btdim,1);
S = zeros(2*n*btdim,1);

pos = 0;
% generate blocks and paste into B
for pair_number = 1:size(M,1)           % loop over the pairs
    w_pm = W(pair_number);
    np = np_vec(pair_number);%size([M{pair_number,1}.Location],1);
    %     if np>2*pmin
    if using_SURF_points
        p = double(M{pair_number,1}.Location);
        q = double(M{pair_number,2}.Location);        
    else
        p = double(M{pair_number,1});
        q = double(M{pair_number,2});
    end
    %%% move to center of mass
    pcm = sum(p,1)./size(p,1);
    p(:,1) = p(:,1)-pcm(1);
    p(:,2) = p(:,2)-pcm(2);
    
    qcm = sum(q,1)./size(q,1);
    q(:,1) = q(:,1)-qcm(1);
    q(:,2) = q(:,2)-qcm(2);
    %%% generate the inverted versions
    pp = [-p(:,2) p(:,1)];
    qp = [-q(:,2) q(:,1)];
    P = [p;-pp];
    Q = [q;-qp];
    %%% determine positions of blocks
    r = sum(4*np_vec(1:pair_number-1))+1;
    rvec = r:r+np*4-1;
    r1 = rvec(1:2*np);          %
    r2 = rvec(2*np+1:end);
    
    c = (adj(pair_number,1)-1) * btdim +1;
    cvec1 = c:c+btdim-1;
    c11 = cvec1(1) * ones(2*np,1);
    c12 = cvec1(2) * ones(2*np,1);
    c13 = cvec1(3) * ones(2*np,1);
    c14 = cvec1(4) * ones(2*np,1);
    
    c = (adj(pair_number,2)-1) * btdim +1;
    cvec2 = c:c+btdim-1;
    c21 = cvec2(1) * ones(2*np,1);
    c22 = cvec2(2) * ones(2*np,1);
    c23 = cvec2(3) * ones(2*np,1);
    c24 = cvec2(4) * ones(2*np,1);
    %%% construct the indices to build sparse matrix
    %Block 1:
    pvec = pos+1:pos+  btdim* 2*np;
    I(pvec) = [r1(:);r1(:);r2(:);r2(:)];
    J(pvec) = [c11;c12;c13;c14];
    S(pvec) = [P(:,1);P(:,2);P(:,1);P(:,2)];
    pos = pos + 2 * btdim*np;
    %Block 2:
    pvec = pos+1:pos+  btdim* 2*np;
    I(pvec) = [r1(:);r1(:);r2(:);r2(:)];
    J(pvec) = [c21;c22;c23;c24];
    S(pvec) = [-Q(:,1);-Q(:,2);-Q(:,1);-Q(:,2)];
    pos = pos + 2 * btdim*np;
    %%% weights vector
    w(rvec) = repmat(w_pm{:},[1,btdim]);
    %%% the part of f corresponding to the fixed tile
    %%% then we need to place x and y values into f
    if (tfix_flag)   % if this layer has a fixed tile in it
        if adj(pair_number,1)==tfix
            %disp('fixing vector f'); disp(['----------- pair_number: ' num2str(pair_number)]);
            f(r:r+np*4-1) =  P;
        elseif adj(pair_number,2)==tfix    % then we need to place x and y values into f
            %disp('fixing vector f'); disp(['----------- pair_number: ' num2str(pair_number)]);
            f(r:r+np*4-1) = -Q;
        end
    end
    %     end
end
%% generate the sparse matrix
D = sparse(I,J,double(S), 2*n,bm);
if tfix_flag
    bexclusion_vec = (btdim*(tfix-1)+1:btdim*(tfix));
    D(:,bexclusion_vec) = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%