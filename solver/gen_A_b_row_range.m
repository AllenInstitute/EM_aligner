function [I, J, S, w] = gen_A_b_row_range(fn, degree, np_vec, ...
                     r_sum_vec, rstart, rend)
% Generate a subset of rows of the matrix A (defined by I J and S) 
% pm: point-match collection
% degree: 1= affine
% ntiles: total number of tiles in full collection
% np_vec a vector indicating the number of point-matches for every point-match set
% n: n * tdim = length of vectors I, J and S. n is length of W
% r_sum_vec = provides the row index position for a specific point-match pair
%                    see: > r_sum_vec(pair_number) = sum(2*np_vec(1:pair_number-1))+1;
% % Designed to run in a parfor like so:
% disp('--------------------------------');
%     disp('Splitting matrix generation');
%     tic
%     npm = size(obj.pm.M,1);    
%     pm_per_worker = round(npm/split);
%     disp(['pm_per_worker=' num2str(pm_per_worker)]);
%     r = zeros(split,2);
%     for ix=1:split
%         pm_min = 1 + (ix-1)*pm_per_worker;
%         if ix < split
%             pm_max = pm_min   + pm_per_worker-1;
%         else
%             pm_max = npm;
%         end
%         r(ix,:) = [pm_min pm_max];
%     end
%     
% disp('determine number of point-pairs for preallocation --- boilerplate');
%     np_vec = zeros(size(obj.pm.M,1),1);
%     for ix = 1:size(obj.pm.M,1)
%             np_vec(ix) = size([obj.pm.M{ix,1}],1);
%     end
%     n = 2*sum(np_vec);
%     m = ncoeff;         
%     r_sum_vec = zeros(size(obj.pm.M,1),1);
%     for pair_number = 1:size(obj.pm.M,1)
%         r_sum_vec(pair_number) = sum(2*np_vec(1:pair_number-1))+1;
%     end
%     disp('generate the matrix itself by splitting and collecting');
%     degree = 1;
%     I = {};
%     J = {};
%     S = {};
%     w = {};
%     parfor ix = 1:size(r,1)
%         
%     [I{ix}, J{ix}, S{ix}, w{ix}] = gen_A_b_row_range(obj.pm, ...
%                                degree, numel(obj.tiles), np_vec,...
%                                2*sum(np_vec(r(ix,1):r(ix,2))), ...
%                                r_sum_vec, r(ix,1), r(ix,2));
% 
%     end
%     disp('Collect: generate the sparse matrix from assembled I, J and S');
%     I1 = cell2mat(I(:));clear I;
%     J1 = cell2mat(J(:));clear J;
%     S1 = cell2mat(S(:));clear S;
%     w = cell2mat(w(:));
%     
%     lsq_options.A = sparse(I1,J1,S1, n,m);
%     lsq_options.b = sparse(size(lsq_options.A,1), 1);
%     lsq_options.W = spdiags(w,0,size(lsq_options.A,1),size(lsq_options.A,1));
%     
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameter definition for polynomials:
% Definition of the parameters
% u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
%     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


load(fn);
M = m;
adj = a;
W = ww;
% M = pm.M;
% adj = pm.adj;
% if ~isfield(pm,'W')
%     W = ones(size(adj,1));
% else
%     W = pm.W;
% end


n = 2*sum(np_vec(rstart:rend));
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
tdim = tdim * 2;        % because we have two dimensions, u and v.
%% calculate A
%m = tdim * ntiles;         % max(adj(:)) gives the number of tiles
w = zeros(n,1);
I = zeros(n*tdim,1);
J= zeros(n*tdim,1);
S = zeros(n*tdim,1);
pos = 0;

% generate blocks and paste into A
for pair_number = rstart:rend%1:size(M,1)           % loop over the pairs
     w_pm = W(pair_number-rstart+1);
    np = np_vec(pair_number);%size([M{pair_number,1}.Location],1);
    %%% determine rvec,  cvec1, cvec2 and s
    r = r_sum_vec(pair_number);%r = sum(2*np_vec(1:pair_number-1))+1;
    rvec = r:r+np*2-1;
    w(rvec) = repmat(w_pm{:}(:)', [1,2]);%%% weights vector

    r1 = rvec(1:np);
    r2 = rvec(np+1:end);
    
     c = (adj(pair_number-rstart+1,1)-1) * tdim +1;
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
    
    
    c = (adj(pair_number-rstart+1,2)-1) * tdim +1;
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

   
    vec1 = [M{pair_number-rstart+1,1}];
    vec2 = [M{pair_number-rstart+1,2}];
    
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
%         S(pvec) = [ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2);...
%             ones(np,1);vec1(:,1);vec1(:,2); vec1(:,1).*vec1(:,2); vec1(:,1).*vec1(:,1); vec1(:,2).*vec1(:,2)];
%         
        S(pvec) = [ones(np,1);...           % 1
                  vec1(:,1);...             % x
                  vec1(:,2);...             % y
                  vec1(:,1).*vec1(:,2);...  % xy
                  vec1(:,1).*vec1(:,1);...  % x2
                  vec1(:,2).*vec1(:,2);...  % y2
                  ones(np,1);...            %1
                  vec1(:,1);...             % x
                  vec1(:,2);...             % y
                  vec1(:,1).*vec1(:,2);...  %xy
                  vec1(:,1).*vec1(:,1);...  %x2
                  vec1(:,2).*vec1(:,2)];... %y2
              
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
end