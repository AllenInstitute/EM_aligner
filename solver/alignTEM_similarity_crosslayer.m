function [D1, D2, f] = alignTEM_similarity_crosslayer(M, adj, tfix,ntiles1,ntiles2, lfix)
%%% COMMENTS needed
%%% build the regularaization term block for the point pair match sets given in M. 
%%% Two blocks are returned because this is a crosslayer coupling, so the
%%% position in the larger final matrix upstream should not be determined
%%% here.
%%% adj provides the positions of entries into the block for every point pair.
%%% tfix is the index of the tile to be fixed
%%% lfix = 1, means fix a tile in this block
%%% lfix = 0, means no tile will be fixed here
%%% This function looks complicated because it is vectorized for efficient
%%% building of the sparse matrix system
%%% Author: Khaled Khairy. Copyright -- 2015 Janelia Research Campus 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(class(M{1}), 'SURFPoints'),
    using_SURF_points = 1;
else
    using_SURF_points = 0;
end
%% determine number of point pairs (to help preallocation)
np_vec = zeros(size(M,1),1);  % np_vec is of length equal to the number of point-pair sets; one set for every pair of tiles
                              % entries into np_vec will be the actual
                              % number of point-pairs for every set
                              % such that sum(np_vec) provides the 
for ix = 1:size(M,1)
    if using_SURF_points
        np_vec(ix) = size([M{ix,1}.Location],1);
    else
        np_vec(ix) = size([M{ix,1}],1);
    end
end
n = 4*sum(np_vec); % n provides the total number of rows for the block (matrix) D generated here.
%% calculate block (matrix) D and block (vector) f
fac = 1;
btdim = 4;  % this is a similarity constraint so only needs four coefficients
%bm = btdim * ntiles;%max(adj(:));
m1 = btdim * ntiles1;%max(adj(:,1));         % gives the number of tiles for layer 1 x no. coeff ==> no. of columns
m2 = btdim * ntiles2;%max(adj(:,2));         % same as above but for second 2

% % B = sparse(2*n,bm);
f = sparse(fac*n,1);

I1 = zeros(n*btdim/2,1);
J1 = zeros(n*btdim/2,1);
S1 = zeros(n*btdim/2,1);

I2 = zeros(n*btdim/2,1);
J2 = zeros(n*btdim/2,1);
S2 = zeros(n*btdim/2,1);


disp(['-- Total number of rows projected in this block n: ' num2str(n)]);
disp(['-- Total number of columns projected in block 1 m1: ' num2str(m1)]);
disp(['-- Total number of columns projected in block 2 m2: ' num2str(m2)]);

pos = 0;
% generate blocks and paste into B
for pair_number = 1:size(M,1)           % loop over the pairs
    np = np_vec(pair_number); % the number of point-matches for this pair.
                              % note: the actual entries into a small block
                              % will be eight times that number
%     if np>2*pmin
        p = double(M{pair_number,1});
        q = double(M{pair_number,2});
        %%% move to center of mass
        pcm = sum(p,1)./size(p,1);
        p(:,1) = p(:,1)-pcm(1);p(:,2) = p(:,2)-pcm(2);
        qcm = sum(q,1)./size(q,1);
        q(:,1) = q(:,1)-qcm(1);q(:,2) = q(:,2)-qcm(2);
        %%% generate the inverted versions
        pp = [-p(:,2) p(:,1)];
        qp = [-q(:,2) q(:,1)];
        P = [p;-pp];
        Q = [q;-qp];
       
        %%% determine positions of blocks
        r = sum(fac *4*np_vec(1:pair_number-1))+1; % each pair-match set gets its own range of rows in the block
                                                   % which means we only
                                                   % need to calcualte r1
                                                   % and r2 once for both
                                                   % D1 and D2 blocks
        rvec = r:r+np*4-1;
        r1 = rvec(1:2*np);          % 
        r2 = rvec(2*np+1:end);
        
        c = (adj(pair_number,1)-1) * btdim +1;    % determine starting column for subblock1
        cvec1 = c:c+btdim-1;                      % this is the column range of indices
        c11 = cvec1(1) * ones(2*np,1);            % we need to duplicate 2*np times to obtain the correct no. of indices
        c12 = cvec1(2) * ones(2*np,1);
        c13 = cvec1(3) * ones(2*np,1);
        c14 = cvec1(4) * ones(2*np,1);
        
        c = (adj(pair_number,2)-1) * btdim +1;
        cvec2 = c:c+btdim-1;
        c21 = cvec2(1) * ones(2*np,1);
        c22 = cvec2(2) * ones(2*np,1);
        c23 = cvec2(3) * ones(2*np,1);
        c24 = cvec2(4) * ones(2*np,1);
        %%% construct the indices and values to build sparse matrix
        %Block 1:
        pvec = pos+1:pos+ 2* btdim* np;
        I1(pvec) = [r1(:);r1(:);r2(:);r2(:)];
        J1(pvec) = [c11;c12;c13;c14];
        S1(pvec) = [P(:,1);P(:,2);P(:,1);P(:,2)];
        %pos = pos + 2 * btdim*np;
        %Block 2:
        pvec = pos+1:pos+  2 * btdim* np;
        I2(pvec) = [r1(:);r1(:);r2(:);r2(:)];
        J2(pvec) = [c21;c22;c23;c24];
        S2(pvec) = [-Q(:,1);-Q(:,2);-Q(:,1);-Q(:,2)];
        
        pos = pos + 2* btdim*np;
       
        %%% the part of d corresponding to the fixed tile
        %%% then we need to place x and y values into d
        if ~isempty(lfix)
            if adj(pair_number,1)==tfix,
                f(r:r+np*4-1) = P;
            elseif adj(pair_number,2)==tfix,    % then we need to place x and y values into b
                f(r:r+np*4-1) = -P; % ???? Q ???
            end
        end
        %     end
end
%% generate the sparse matrix
D1 = sparse(I1,J1,double(S1),  n,m1);
D2 = sparse(I2,J2,double(S2),  n,m2);

%% estimate parameters under similarity constraint
 bexclusion_vec = (btdim*(tfix-1)+1:btdim*(tfix));
 if lfix==1
     D1(:,bexclusion_vec) = [];
 elseif lfix==2
     D2(:,bexclusion_vec) = [];
 end
    
%% B(:,bexclusion_vec) = [];
% xcon = B\d;
% %% Construct the Tikhonov system
% exclusion_vec = (tdim*(tfix-1)+1:tdim*(tfix));
% 
% Bd = ones(ntiles*tdim,1);
% Bd(3:3:end) = 0;% 0 = do not constrain translation
% B = sparse(diag(Bd));
% d = zeros(ntiles*tdim,1);
% 
% for ix = 1:ntiles-1
%     bloc = (btdim*(ix-1))+1;
%     t =  xcon(bloc:bloc+3);
%     T =[t(1) t(2) 0 t(3) t(4) 0];
%     d((ix-1)*6 + 1: ix*6) = T(:);
% end
% B(exclusion_vec,:) = [];
% B(:,exclusion_vec) = [];
% d = sparse(d);
% d(exclusion_vec) = [];