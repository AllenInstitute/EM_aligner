function Tp = poly_expand_affines(T, degree)
%% Given input array T is (n x 6) where each row is an affine
%  returns Tp n x tdim vector of coefficients with polynomial dimensions and coefficient order
%
% For affines the coefficients are ordered like this:
% u = a2x+a3y+a1;
%
% for up to third degree
% u = a1 + a2 * x + a3 * y + a4 * xy + a5 * x^2 + a6 * y^2 +
%     a7 *x^2 * y + a8 * x * y^2 + a9 * x^3 + a10 * y^3
% this follows the definition of gen_A_b_row_range.m, and therefore the convention
% for matrix A
% We also need to re-order coefficients so that Tp complies with 
% the above convention
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
if size(T,2)~=6
    error('Size T must be n x 6');
end
tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for polynomial
tdim = tdim * 2;              % because we have two dimensions, u and v
% how many zeros to insert?
ninsert = tdim/2-3;  % for each dimension the first three coefficients come from the affine

if degree==2
    Tp = [T(:,3) T(:,1) T(:,2) zeros(size(T,1), ninsert) T(:,6) T(:,4) T(:,5) zeros(size(T,1), ninsert)];
end

