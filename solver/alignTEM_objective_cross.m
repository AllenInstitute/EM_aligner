function [A1, A2, b] = alignTEM_objective_cross(M, adj,tfix, lfix, degree, sf)
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
%% Generate matrices A1 and A2 for the cross-layer points
% matrix A1 contains the blocks relevant to the lower layer
% and matrix A2 only the blocks for the upper layer
if strcmp(class(M{1}), 'SURFPoints'),
    using_SURF_points = 1;
else
    using_SURF_points = 0;
end
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
m1 = tdim * max(adj(:,1));         % gives the number of tiles for layer 1 x no. coeff
m2 = tdim * max(adj(:,2));         % same as above but for layer 2

I1 = zeros(n*tdim/2,1);
J1 = zeros(n*tdim/2,1);
S1 = zeros(n*tdim/2,1);

I2 = zeros(n*tdim/2,1);
J2 = zeros(n*tdim/2,1);
S2 = zeros(n*tdim/2,1);

Ib = [];
Sb = [];
pos = 0;
% generate blocks and paste into A
for pair_number = 1:size(M,1)           % loop over the pairs
    np = np_vec(pair_number);%size([M{pair_number,1}.Location],1);
    %%% determine rvec,  cvec1, cvec2 and s
    % For 2D Affine transformation
    r = sum(2*np_vec(1:pair_number-1))+1;
    rvec = r:r+np*2-1;
    r1 = rvec(1:np);
    r2 = rvec(np+1:end);
    
    c = (adj(pair_number,1)-1) * tdim +1;
    cvec1 = c:c+tdim-1;
    if tdim>=6              % affine, degree==1 and tdim at least 6
        c11 = ones(np,1)*cvec1(1);
        c12 = ones(np,1)*cvec1(2);
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
    if tdim>=20             % third degree polynomial and tdim at least 12
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
    if tdim>=6              % affine, degree==1 and tdim at least 6
        c21 = ones(np,1)*cvec2(1);
        c22 = ones(np,1)*cvec2(2);
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
    if tdim>=20             % third degree polynomial and tdim at least 12
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
    
    %%% store the indices and values in I J and S
    % Block 1
    pvec = pos+1:pos+tdim*np;
    
    if tdim==6
        I1(pvec) = [r1(:);r1(:);r1(:);r2(:);r2(:);r2(:)];
        J1(pvec) = [c11;c12;c13;c14;c15;c16];
        S1(pvec) = [vec1(:,1);vec1(:,2);ones(np,1);vec1(:,1);vec1(:,2);ones(np,1)];
        
    elseif tdim==12
        I1(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 2nd degree polynomial
        J1(pvec) = [c11;c12;c13;c14;c15;c16;c17;c18;c19;c110;c111;c112];
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2
        S1(pvec) = [ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2);...
            ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2)];
        
    elseif tdim == 20
        I1(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);...
            r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 3rd degree polynomial
        J1(pvec) = [c11;c12;c13;c14;c15;c16;c17;c18;c19;c110;c111;c112;c113;c114;c115;c116;c117;c118;c119;c120];
        % Definition of the parameters
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
        %     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
        S1(pvec) = [ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2); ...
            vec1(:,1) .* vec1(:,1) .* vec1(:,2); vec1(:,1).*vec1(:,2).*vec1(:,2); vec1(:,1).*vec1(:,1).*vec1(:,1);...
            vec1(:,2).*vec1(:,2).*vec1(:,2); ...
            ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2); ...
            vec1(:,1) .* vec1(:,1) .* vec1(:,2); vec1(:,1).*vec1(:,2).*vec1(:,2); vec1(:,1).*vec1(:,1).*vec1(:,1);...
            vec1(:,2).*vec1(:,2).*vec1(:,2)
            ];
    end
    
    %pos = pos + tdim*np;
    % Block 2
    pvec = pos+1:pos+tdim*np;
    if tdim==6
        I2(pvec) = [r1(:);r1(:);r1(:);r2(:);r2(:);r2(:)]; % for affine, i.e. tdim = 6
        J2(pvec) = [c21;c22;c23;c24;c25;c26];
        S2(pvec) = -[vec2(:,1);vec2(:,2);ones(np,1);vec2(:,1);vec2(:,2);ones(np,1)];
        
    elseif tdim==12
        I2(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 2nd degree polynomial
        J2(pvec) = [c21;c22;c23;c24;c25;c26;c27;c28;c29;c210;c211;c212];
        % v = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2
        S2(pvec) = -[ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2);...
            ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2)];
        
    elseif tdim==20
        I2(pvec) = [r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);r1(:);...
            r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:);r2(:)]; % for 3rd degree polynomial
        J2(pvec) = [c21;c22;c23;c24;c25;c26;c27;c28;c29;c210;c211;c212;c213;c214;c215;c216;c217;c218;c219;c220];
        % Definition of the parameters
        % u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
        %     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
        S2(pvec) = -[ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2); ...
            vec2(:,1) .* vec2(:,1) .* vec2(:,2); vec2(:,1).*vec2(:,2).*vec2(:,2); vec2(:,1).*vec2(:,1).*vec2(:,1);...
            vec2(:,2).*vec2(:,2).*vec2(:,2); ...
            ones(np,1);vec2(:,1);vec2(:,2); vec2(:,1).*vec2(:,2); vec2(:,1).*vec2(:,1); vec2(:,2).*vec2(:,2); ...
            vec2(:,1) .* vec2(:,1) .* vec2(:,2); vec2(:,1).*vec2(:,2).*vec2(:,2); vec2(:,1).*vec2(:,1).*vec2(:,1);...
            vec2(:,2).*vec2(:,2).*vec2(:,2);
            ];
    end
    pos = pos + tdim*np;
    % it is safe to assume that the first column of adj refers to tile
    % indices of the lower layer, and the second of the upper layer
    if (tfix)
        if adj(pair_number,1)==tfix && lfix==1,
            Ib = [Ib;rvec(:)];
            Sb = [Sb;vec1(:)];
        end
        if adj(pair_number,2)==tfix && lfix==2, % i.e. we fixed tile in upper layer
            Ib = [Ib;rvec(:)];
            Sb = [Sb;-vec2(:)];
        end
    end
end

%% generate the sparse matrix
A1 = sparse(I1,J1,double(S1), n,m1);
A2 = sparse(I2,J2,double(S2), n,m2);
%% % build the constraint (fix tile # tfix) into matrix A
if tfix,
    b = sparse(Ib,ones(length(Ib),1), double(Sb),n,1);
    exclusion_vec = (tdim*(tfix-1)+1:tdim*(tfix));
    if lfix==1
        A1(:,exclusion_vec) = [];
    elseif lfix==2
        A2(:,exclusion_vec) = [];
    end
else
    b = sparse(size(A1,1),1);
end
