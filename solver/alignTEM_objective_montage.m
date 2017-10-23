function [A, b, w, tfix] = alignTEM_objective_montage(pm,tfix_flag, tfix, degree, sf, ntiles)
M = pm.M;
adj = pm.adj;
if ~isfield(pm,'W')
    W = ones(size(adj,1));
else
    W = pm.W;
end
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
%% Generate matrices for the objective function (term 1).
if strcmp(class(M{1}), 'SURFPoints'),
    using_SURF_points = 1;
else
    using_SURF_points = 0;
end

%ntiles = max(adj(:));

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
%% calculate A
m = tdim * ntiles;         % max(adj(:)) gives the number of tiles
w = zeros(n,1);
I = zeros(n*tdim,1);
J= zeros(n*tdim,1);
S = zeros(n*tdim,1);
Ib = [];
Sb = [];
pos = 0;
r_sum_vec = zeros(size(M,1),1);
parfor pair_number = 1:size(M,1)
    r_sum_vec(pair_number) = sum(2*np_vec(1:pair_number-1))+1;
end
% generate blocks and paste into A
for pair_number = 1:size(M,1)           % loop over the pairs
    w_pm = W(pair_number);
    np = np_vec(pair_number);%size([M{pair_number,1}.Location],1);
    %%% determine rvec,  cvec1, cvec2 and s
    r = r_sum_vec(pair_number);%r = sum(2*np_vec(1:pair_number-1))+1;
    rvec = r:r+np*2-1;
    r1 = rvec(1:np);
    r2 = rvec(np+1:end);
    
    c = (adj(pair_number,1)-1) * tdim +1;
    cvec1 = c:c+tdim-1;
    if tdim>=2              % degree == 0 , i.e. only translation
        c11 = ones(np,1)*cvec1(1);
        c12 = ones(np,1)*cvec1(2);
    end
    if tdim>=6              % affine, degree==1 and tdim at least 6
        c13 = ones(np,1)*cvec1(3);
        c14 = ones(np,1)*cvec1(4);
        c15 = ones(np,1)*cvec1(5);
        c16 = ones(np,1)*cvec1(6);
    end
    if tdim>=12             % second degree polynomial and tdim at least 12
        c17 = ones(np,1)*cvec1(7);
        c18 = ones(np,1)*cvec1(8);
        c19 = ones(np,1)*cvec1(9);
        c110 = ones(np,1)*cvec1(10);
        c111 = ones(np,1)*cvec1(11);
        c112 = ones(np,1)*cvec1(12);
    end
    if tdim>=20             % third degree polynomial and tdim at least 20
        c113 = ones(np,1)*cvec1(13);
        c114 = ones(np,1)*cvec1(14);
        c115 = ones(np,1)*cvec1(15);
        c116 = ones(np,1)*cvec1(16);
        c117 = ones(np,1)*cvec1(17);
        c118 = ones(np,1)*cvec1(18);
        c119 = ones(np,1)*cvec1(19);
        c120 = ones(np,1)*cvec1(20);
    end
    
    
    c = (adj(pair_number,2)-1) * tdim +1;
    cvec2 = c:c+tdim-1;
    if tdim>=2              % affine, degree==0 so tdim at least 2
        c21 = ones(np,1)*cvec2(1);
        c22 = ones(np,1)*cvec2(2);
    end
    if tdim>=6              % affine, degree==1 so tdim at least 6
        c23 = ones(np,1)*cvec2(3);
        c24 = ones(np,1)*cvec2(4);
        c25 = ones(np,1)*cvec2(5);
        c26 = ones(np,1)*cvec2(6);
    end
    if tdim>=12             % second degree polynomial and tdim at least 12
        c27 = ones(np,1)*cvec2(7);
        c28 = ones(np,1)*cvec2(8);
        c29 = ones(np,1)*cvec2(9);
        c210 = ones(np,1)*cvec2(10);
        c211 = ones(np,1)*cvec2(11);
        c212 = ones(np,1)*cvec2(12);
    end
    if tdim>=20             % third degree polynomial and tdim at least 20
        c213 = ones(np,1)*cvec2(13);
        c214 = ones(np,1)*cvec2(14);
        c215 = ones(np,1)*cvec2(15);
        c216 = ones(np,1)*cvec2(16);
        c217 = ones(np,1)*cvec2(17);
        c218 = ones(np,1)*cvec2(18);
        c219 = ones(np,1)*cvec2(19);
        c220 = ones(np,1)*cvec2(20);
    end
    
    if using_SURF_points
        vec1 = [M{pair_number,1}.Location];
        vec2 = [M{pair_number,2}.Location];
    else
        vec1 = [M{pair_number,1}];
        vec2 = [M{pair_number,2}];
    end
    % scale
    vec1(:,1) = vec1(:,1) / sf(1);
    vec1(:,2) = vec1(:,2) / sf(2);
    vec2(:,1) = vec2(:,1) / sf(1);
    vec2(:,2) = vec2(:,2) / sf(2);
    
    %%% store indices and values in I J and S
    % Block 1
    pvec = pos+1:pos+tdim*np;
    if tdim==2
        I(pvec) = [r1(:);r2(:)]; % for translation only, i.e. tdim = 2
        J(pvec) = [c11;c12];
        S(pvec) = [ones(np,1);ones(np,1)];
        
    elseif tdim==6
        I(pvec) = [r1(:);r1(:);r1(:);r2(:);r2(:);r2(:)]; % for affine, i.e. tdim = 6
        J(pvec) = [c11;c12;c13;c14;c15;c16];
        S(pvec) = [vec1(:,1);vec1(:,2);ones(np,1);vec1(:,1);vec1(:,2);ones(np,1)];
    elseif tdim==12
        I(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 2nd degree polynomial
        J(pvec) = [c11;c12;c13;c14;c15;c16;c17;c18;c19;c110;c111;c112];
        % Definition of parameters
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2
        S(pvec) = [ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2);...
            ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2)];
    elseif tdim == 20
        I(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);...
            r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 3rd degree polynomial
        J(pvec) = [c11;c12;c13;c14;c15;c16;c17;c18;c19;c110;c111;c112;c113;c114;c115;c116;c117;c118;c119;c120];
        % Definition of the parameters
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
        %     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
        S(pvec) = [ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2); ...
            vec1(:,1) .* vec1(:,1) .* vec1(:,2); vec1(:,1).*vec1(:,2).*vec1(:,2); vec1(:,1).*vec1(:,1).*vec1(:,1);...
            vec1(:,2).*vec1(:,2).*vec1(:,2); ...
            ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2); ...
            vec1(:,1) .* vec1(:,1) .* vec1(:,2); vec1(:,1).*vec1(:,2).*vec1(:,2); vec1(:,1).*vec1(:,1).*vec1(:,1);...
            vec1(:,2).*vec1(:,2).*vec1(:,2)
            ];
    end
    pos = pos + tdim*np;
    
    % Block 2
    pvec = pos+1:pos+tdim*np;
    if tdim==2
        I(pvec) = [r1(:);r2(:)]; % for translation, i.e. tdim = 2
        J(pvec) = [c21;c22];
        S(pvec) = -[ones(np,1);ones(np,1)];
    elseif tdim==6
        I(pvec) = [r1(:);r1(:);r1(:);r2(:);r2(:);r2(:)]; % for affine, i.e. tdim = 6
        J(pvec) = [c21;c22;c23;c24;c25;c26];
        S(pvec) = -[vec2(:,1);vec2(:,2);ones(np,1);vec2(:,1);vec2(:,2);ones(np,1)];
    elseif tdim==12
        I(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 2nd degree polynomial
        J(pvec) = [c21;c22;c23;c24;c25;c26;c27;c28;c29;c210;c211;c212];
        % Definition of the parameters
        % v = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2
        S(pvec) = -[ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2);...
            ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2)];
        
    elseif tdim==20
        I(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);...
            r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 3rd degree polynomial
        J(pvec) = [c21;c22;c23;c24;c25;c26;c27;c28;c29;c210;c211;c212;c213;c214;c215;c216;c217;c218;c219;c220];
        % Definition of the parameters
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
        %     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
        S(pvec) = -[ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2); ...
            vec2(:,1) .* vec2(:,1) .* vec2(:,2); vec2(:,1).*vec2(:,2).*vec2(:,2); vec2(:,1).*vec2(:,1).*vec2(:,1);...
            vec2(:,2).*vec2(:,2).*vec2(:,2); ...
            ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2); ...
            vec2(:,1) .* vec2(:,1) .* vec2(:,2); vec2(:,1).*vec2(:,2).*vec2(:,2); vec2(:,1).*vec2(:,1).*vec2(:,1);...
            vec2(:,2).*vec2(:,2).*vec2(:,2);
            ];
    end
    pos = pos + tdim*np;
    %%% weights vector
    w(rvec) = repmat(w_pm{:}(:)', [1,2]);
    %%% special case for the part of b corresponding to the fixed tile
    %%% then we need to place x and y values into b
    %%% This is relevant for translation only
    %if (tfix_flag)   % currently only in the case of polynomial degree zero (i.e. translation only)
    if tdim==2
            Ib = [Ib;rvec(:)];
            Sb = [Sb;-(vec1(:)-vec2(:))];
%         if adj(pair_number,1)==tfix,
%             Ib = [Ib;rvec(:)];
%             Sb = [Sb;-(vec1(:)-vec2(:))];
%             %disp([pair_number adj(pair_number,:)]);
%             %%% sosi
%             
%         elseif adj(pair_number,2)==tfix,    % then we need to place x and y values into b
%             Ib = [Ib;rvec(:)];
%             Sb = [Sb;-(vec1(:)-vec2(:))];
%         else
%             Ib = [Ib;rvec(:)];
%             Sb = [Sb;-(vec1(:) - vec2(:))];
%         end
    end
    if tdim>2
        if adj(pair_number,1)==tfix,
            Ib = [Ib;rvec(:)];
            %Sb = [Sb;-(vec1(:)-vec2(:))];
            Sb  = [Sb;-vec1(:)];

            
        elseif adj(pair_number,2)==tfix,    % then we need to place x and y values into b
            Ib = [Ib;rvec(:)];
%             Sb = [Sb;-(vec1(:)-vec2(:))];
            Sb = [Sb;vec2(:)];
        else
%             Ib = [Ib;rvec(:)];
%             Sb = [Sb;(vec1(:) - vec2(:))];
        end
    end
end

%% generate the sparse matrix
A = sparse(I,J,double(S), n,m);
%% % build the constraint (fix tile # tfix) into matrix A
b = sparse(Ib,ones(length(Ib),1), double(Sb),n,1);
if tfix_flag,
    
    exclusion_vec = (tdim*(tfix-1)+1:tdim*(tfix));
    A(:,exclusion_vec) = [];
else
    %b = sparse(size(A,1),1);
end
