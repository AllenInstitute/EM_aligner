function [x1, y1, tids, L1, cm] = get_tile_centers(rc, z, plot_flag)
%%%% fast way to get tile ids, centers and minimal Msection object
if nargin<3, plot_flag = 0;end
tids = {};
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
    rc.baseURL, rc.owner, rc.project, rc.stack,z );
wo = weboptions('Timeout', 60);j = webread(urlChar, wo);
jt1 = tile;
sectionID = j(1).layout.sectionId;
x1 = zeros(numel(j),1);
y1 = zeros(numel(j),1);
for jix = 1:numel(j)
    jt1(jix) = tile(j(jix));
    tids{jix} = jt1(jix).renderer_id;
    %     x(jix) = jt1(jix).tform.T(3,1) - jt1(jix).W/2;
    %     y(jix) = jt1(jix).tform.T(3,2) - jt1(jix).H/2;
    
    x = 0;
    y = 0;
    Px = [x; x + jt1(jix).W; x + jt1(jix).W; x];
    Py = [y; y    ; y + jt1(jix).H; jt1(jix).H];
    %P = [Px(:) Py(:)];
    %%% transform the points and then plot the patch
    if strcmp(class(jt1(jix).tform), 'affine2d')
        P = [Px(:) Py(:) [1 1 1 1]']*jt1(jix).tform.T;
    else
        P = transformPointsInverse(jt1(jix).tform,[Px Py]);
    end
    cm(jix,:) = sum([P(:,1)/4 P(:,2)/4],1);
    x1(jix,1) = cm(jix,1);
    y1(jix,1) = cm(jix,2);
end
% x1 = x1(:);
% y1 = y1(:);


if nargout>3
    L1 = Msection;
    L1.sectionID = sectionID;
    L1.tiles = jt1;
    L1.X = x1(:);
    L1.Y = y1(:);
    L1.z = z;
end

if plot_flag
figure;
[obj, h, rh, A, cm] = show_map(L1);drawnow; % first overlap section of fixed
hold on;
plot(cm(:,1), cm(:,2), '*b');
end
