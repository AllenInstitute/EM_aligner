%%% test intensity correction
rc.stack = 'four_tile_acquire';
rc.project = 'test_warp_field';
rc.owner = 'flyTEM';
rc.service_host           = '10.37.5.60:8080';    % use of ip adress is preferred (no DNS lookup)--Note: 10.37.5.60 is a VM, 10.40.3.162 is tem-services
rc.baseURL                = ['http://' rc.service_host '/render-ws/v1']; 
rc.verbose                = 0;


pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner  = 'flyTEM';
pm.match_collection = 'FAFB_pm_7';
        
pmopts.NumRandomSamplingsMethod = 'Desired confidence';
pmopts.MaximumRandomSamples = 3000;
pmopts.DesiredConfidence = 99.5;
pmopts.PixelDistanceThreshold = 1;
    
opts.nbrs = 0;
opts.min_points = 3;
opts.max_points = 30;
opts.filter_point_matches = 1;
opts.pmopts = pmopts;


dir_scratch = '/Users/khairyk/Documents/MATLAB/mwork_mac/temp';

%% load section and tile-pair point-matches
L = Msection(rc,1);

[zu, sID, sectionId, z, ns] = get_section_ids(rc,1,1);
[T, map_id, tIds, z_val, r, c] = load_all_transformations(rc,...
        zu, dir_scratch);
[M, adj, W, np] = system_solve_helper_load_point_matches(...
        zu, opts, pm, map_id, ...
        sID, size(T,1), r, c);

%% read images
imo = webread(sprintf('http://tem-services.int.janelia.org:8080/render-ws/v1/owner/flyTEM/project/test_warp_field/stack/four_tile_acquire/tile/%s/jpeg-image', ...
    L.tiles(1).renderer_id));
I = zeros(size(imo,1), size(imo,2),numel(L.tiles));
im = [];
for tix = 1:numel(L.tiles)
urlChar = sprintf('http://tem-services.int.janelia.org:8080/render-ws/v1/owner/flyTEM/project/test_warp_field/stack/four_tile_acquire/tile/%s/jpeg-image', ...
    L.tiles(tix).renderer_id);
    imo = webread(urlChar);
    I(:,:,tix) = imo(:,:,1);
    imshow(mat2gray(I(:,:,tix)));drawnow;
end
I = mat2gray(I);
%% obtain gray-scale values from I, corresponding to entries in M

GS  = {};
for pix = 1:size(M,1)
    im1 = I{adj(pix,1)};
    indx1 = sub2ind(size(im1), round(M{pix,1}(:,2)), round(M{pix,1}(:,1)));
    GS{pix,1} = im1(indx1);
    
    im2 = I{adj(pix,2)};
    indx2 = sub2ind(size(im2), round(M{pix,2}(:,2)), round(M{pix,2}(:,1)));
    GS{pix,2} = im2(indx2);
end

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

degree = 1;

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
% pair 1,2
A = [p12 -q12];

% pair 1,3
A(size(p12,1)+1:size(p12,1) + size(p13,1), v1) = p13;
A(size(p12,1)+1:size(p12,1) + size(p13,1), v3) = -q13;
% % pair 2,4
sa = size(A,1);
A(sa+1: sa+size(p24,1), v2) = p24;
A(sa+1: sa+size(p24,1), v4) = -q24;

% % pair 3,4
sa = size(A,1);
A(sa+1: sa+size(p34,1), v3) = p34;
A(sa+1: sa+size(p34,1), v4) = -q34;


b = zeros(size(A,1),1);

v12 = Gs12_1(:)-Gs12_2(:);
v13 = Gs13_1(:)-Gs13_2(:);
v24 = Gs24_1(:)-Gs24_2(:);
v34 = Gs34_1(:)-Gs34_2(:);
% 
% b = [v12;v13;zeros(size(v23,1),1)];
b =   double([v12;v13;v24;v34]);
% 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for the case with no prior, we fix tile 1
% b(1:size(p1,1)) = -[Gs2(:)'- Gs1(:)'];
A = A(:,tdim+1:end);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xsol = A\b;
clc;
disp(xsol)
xsol(100) = 0;

% % apply correction to tiles

y = [1:size(I,1)]';
imy = y(:,ones(1,size(I,2)));
x = [1:size(I,2)]';
imx = [x(:,ones(1,size(I,1)))]';

%%%% in case of degree 1
if degree==1
im2 = xsol(1) + ...
      xsol(2).*imx +...
      xsol(3).*imy;


im3 = xsol(4) + ...
      xsol(5).*imx +...
      xsol(6).*imy;
  
im4 = xsol(7) + ...
      xsol(8).*imx +...
      xsol(9).*imy;
end
if degree==2
%%%% in case of degree 2
im2 = xsol(1) + ...
      xsol(2).*imx +...
      xsol(3).*imy + ...
      xsol(4).*imx.*imx + ...
      xsol(5).*imx.*imy + ...
      xsol(6).*imy.*imy;


im3 = xsol(7) + ...
      xsol(8).*imx +...
      xsol(9).*imy + ...
      xsol(10).*imx.*imx + ...
      xsol(11).*imx.*imy + ...
      xsol(12).*imy.*imy;
  
im4 = xsol(13) + ...
      xsol(14).*imx +...
      xsol(15).*imy + ...
      xsol(16).*imx.*imx + ...
      xsol(17).*imx.*imy + ...
      xsol(18).*imy.*imy;
end

I_corr = I; 
I_corr(:,:,2) = I(:,:,2) - im2;
I_corr(:,:,3) = I(:,:,3) - im3;
I_corr(:,:,4) = I(:,:,4) - im4;

imshowpair(I(:,:,2), I_corr(:,:,2), 'montage');




    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    