%% construct linear system for intensity correction and solve
degree = 1;
M = Logs.pm.M;
adj = Logs.pm.adj;
%% set up linear system
Gs12_1  = GS{2,1};
Gs12_2  = GS{2,2};
m12_1 = M{2,1};
m12_2 = M{2,2};

Gs13_1  = GS{1,1};
Gs13_2  = GS{1,2};
m13_1 = M{1,1};
m13_2 = M{1,2};

Gs24_1  = GS{4,1};
Gs24_2  = GS{4,2};
m24_1 = M{4,1};
m24_2 = M{4,2};

Gs34_1  = GS{3,1};
Gs34_2  = GS{3,2};
m34_1 = M{3,1};
m34_2 = M{3,2};

if degree == 0
    tdim=1;
    v1 = 1;
    v2 = 2;
    v3 = 3;
    v4 = 4;
end

if degree==1
tdim = 3;
v1 = 1:3;
v2 = 4:6;
v3 = 7:9;
v4 = 10:12;
end
if degree==2
    tdim = 6;
    v1 = 1:6;
    v2 = 7:12;
    v3 = 13:18;
    v4 = 19:24;
end

p12 = get_poly_basis_block(m12_1, degree);% [ones(size(m12_1, 1),1) m12_1(:,2) m12_1(:,1) m12_1(:,2).*m12_1(:,2) m12_1(:,2).*m12_1(:,1) m12_1(:,1).*m12_1(:,1)];
q12 = get_poly_basis_block(m12_2, degree);%[ones(size(m12_1, 1),1) m12_2(:,2) m12_2(:,1) m12_2(:,2).*m12_2(:,2) m12_2(:,2).*m12_2(:,1) m12_2(:,1).*m12_2(:,1)];

p13 = get_poly_basis_block(m13_1, degree);%[ones(size(m13_1, 1),1) m13_1(:,2) m13_1(:,1) m13_1(:,2).*m13_1(:,2) m13_1(:,2).*m13_1(:,1) m13_1(:,1).*m13_1(:,1)];
q13 = get_poly_basis_block(m13_2, degree);%[ones(size(m13_1, 1),1) m13_2(:,2) m13_2(:,1) m13_2(:,2).*m13_2(:,2) m13_2(:,2).*m13_2(:,1) m13_2(:,1).*m13_2(:,1)];

p24 = get_poly_basis_block(m24_1, degree);%[ones(size(m23_1, 1),1) m23_1(:,2) m23_1(:,1) m23_1(:,2).*m23_1(:,2) m23_1(:,2).*m23_1(:,1) m23_1(:,1).*m23_1(:,1)];
q24 = get_poly_basis_block(m24_2, degree);%[ones(size(m23_1, 1),1) m23_2(:,2) m23_2(:,1) m23_2(:,2).*m23_2(:,2) m23_2(:,2).*m23_2(:,1) m23_2(:,1).*m23_2(:,1)];

p34 = get_poly_basis_block(m34_1, degree);%[ones(size(m23_1, 1),1) m23_1(:,2) m23_1(:,1) m23_1(:,2).*m23_1(:,2) m23_1(:,2).*m23_1(:,1) m23_1(:,1).*m23_1(:,1)];
q34 = get_poly_basis_block(m34_2, degree);%[ones(size(m23_1, 1),1) m23_2(:,2) m23_2(:,1) m23_2(:,2).*m23_2(:,2) m23_2(:,2).*m23_2(:,1) m23_2(:,1).*m23_2(:,1)];


A = [];
% % pair 1,2
A = [p12 -q12];
% 
% % pair 1,3
A(size(p12,1)+1:size(p12,1) + size(p13,1), v1) = p13;
A(size(p12,1)+1:size(p12,1) + size(p13,1), v3) = -q13;

% % pair 2,4
sa = size(A,1);
A(sa+1: sa+size(p24,1), v2) = p24;
A(sa+1: sa+size(p24,1), v4) = -q24;

% % % pair 3,4
sa = size(A,1);
A(sa+1: sa+size(p34,1), v3) = p34;
A(sa+1: sa+size(p34,1), v4) = -q34;


b = zeros(size(A,1),1);

v12 = Gs12_1(:)-Gs12_2(:) - Gs12_1;
v13 = Gs13_1(:)-Gs13_2(:) - Gs13_1;
v24 = Gs24_1(:)-Gs24_2(:);
v34 = Gs34_1(:)-Gs34_2(:);

% v12 = Gs12_1(:)-Gs12_2(:);
% v13 = Gs13_1(:)-Gs13_2(:);
%v24 = Gs24_1(:)-Gs24_2(:);
%v34 = Gs34_1(:)-Gs34_2(:);

b =   double([v12;v13;v24;v34]);
% b =   double([-v12;-v13]);b(size(A,1)) = 0;
% 
% b = double([v12; v13; v34]);
% b = double([v12]);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for the case with no prior, we fix tile 1
A = A(:,tdim+1:end);
xsol = A\b;
xsol = [zeros(tdim, 1);xsol];%xsol(12) = 0;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% d = zeros(size(A,2),1);
% lambda = 1;
% K  = A'*A + lambda;
% Lm  = A'*b + lambda*d;
% %     [x2, R] = solve_AxB(K,Lm, opts, d);
% xsol = K\Lm;xsol = [xsol];

clc;
disp(xsol)






































