function T = rigid_transformation_gen(rcsource, pm, s1, s2, dir_scratch)
% determine a rigid transformation between sections s1 and s2


% configure
if nargin<5, dir_scratch = tempdir;end
wopts = weboptions;
wopts.Timeout = 20;

opts.min_points = 8;
opts.max_points = inf;

% find section ids and map ids
[zu, sID, sectionId, z, ns] = get_section_ids(rcsource, s1, s2);
[Transformations, map_id, tIds, z_val] = ...
    load_all_transformations(rcsource, zu, dir_scratch);

% find all point matches between the two sections
[M, adj, W, np] = load_cross_section_pm(pm, sID{1}, sID{end}, ...
    map_id, opts.min_points, opts.max_points, wopts, 1);

% transform each local coordinate set to world coordinates
for tix = 1:size(M,1)
    % for first tile
    T = Transformations(adj(tix,1),:);
    T = reshape(T, 3, 2);
    T(3,3) = 1;
    tform = affine2d(T);
    [X1, Y1] = transformPointsForward(tform, M{tix,1}(:,1), M{tix,1}(:,2));
    M{tix,1}(:,1) = X1;
    M{tix,1}(:,2) = Y1;
    
    
    % for second tile
    T = Transformations(adj(tix,2),:);
    T = reshape(T, 3, 2);
    T(3,3) = 1;
    tform = affine2d(T);
    [X2, Y2] = transformPointsForward(tform, M{tix,2}(:,1), M{tix,2}(:,2));
    M{tix,2}(:,1) = X2;
    M{tix,2}(:,2) = Y2;
    
end

PM.M = M;
PM.adj = adj;
PM.W = W;
PM.np = np;

%PM = filter_pm(PM);
% concatenate all point-matches into one array [X1 Y1 X2 Y2]
m = cell2mat(PM.M);
X1 = m(:,1);
Y1 = m(:,2);
X2 = m(:,3);
Y2 = m(:,4);
% detemine rotation only
A = [X1 Y1];
B = [X2 Y2];

assert(size(A,1)==size(B,1));
centroid_A = mean(A);
centroid_B = mean(B);
% disp('-- Building linear system for rotation');
N = size(A,1);
H = (A-repmat(centroid_A,N,1))' * (B-repmat(centroid_B,N,1));
[U,S,V] = svd(H);
R = V*U';
if det(R)<0  % detect reflection special case
    V(:,1) = V(:,1) * (-1);
    R = V*U';
end
% determine translation only
U = [X1 Y1];% + repmat(t(:)', length(X1),1);
V = [X2 Y2] *R;
warning off; x = ones(length(X1),2)\(V-U);warning on;
V = V - repmat(x(1,:), length(X1),1);
T2 = zeros(3,3);
T2(3,3) = 1;
T2([3 6]) = x(1,:);
% combine the two
Tr = zeros(3,3);
Tr(3,3) = 1;
Tr(1:2,1:2) = R;
T = -T2  + Tr;
T(3,3) = 1;
