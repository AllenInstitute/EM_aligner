function [x1, y1] = get_tile_centers_tile_array(jt1)
%%%% fast way to get tile ids, centers and minimal Msection object
ntiles = numel(jt1);
x1 = zeros(ntiles,1);
y1 = zeros(ntiles,1);
parfor jix = 1:ntiles
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
    cm = sum([P(:,1)/4 P(:,2)/4],1);
    x1(jix,1) = cm(1);
    y1(jix,1) = cm(2);
end
x1 = x1(:);
y1 = y1(:);
