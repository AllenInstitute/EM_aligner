function [mA, FitMeanAreas] = calculate_mean_tile_areas_by_section_and_fit(jtiles, zu)
%% fix global section scale
% [~, tiles11] = get_slab_tiles(rcfixed, 1, overlap(1)-1);
% 
%  Lall = Msection([tiles11(:)' tiles21t(:)' tiles22t(:)']);
% jtiles = Lall.tiles;

% zu = 1:Lall.tiles(end).z;
% [zu] = get_section_ids(rcmoving, overlap(1), rcmoving.nlast);
%%
tic
edges = [1:.01:2];
%counts = zeros(numel(zu), numel(edges));
for zix = 1:numel(zu)
    indx = find([jtiles(:).z]==zu(zix));
    jt1 = jtiles(indx);
    Ar = [];
    Aratio = [];
    S  = [];
    count = 1;
    for jix = 1:numel(jt1)
        %jt1(jix) = tile(j(jix));
        %tids{jix} = jt1(jix).renderer_id;
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
        %cm(jix,:) = sum([P(:,1)/4 P(:,2)/4],1);
        % check polygon area
        Ar(count) = polyarea(P(:,1), P(:,2));
        Aratio(count) = Ar(count)/(jt1(jix).H * jt1(jix).W);
%         % add polygonperimeter
%         s = 0;
%         s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
%         s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
%         s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
%         s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
%         S(zix, count) = s;
        count = count + 1;
    end
    %counts(zix,:) = histc(Aratio, edges, 2);
    mA(zix) = median(Aratio);
end
toc
% % calculate scale needed to restore the dataset to reasonable scale
% p = polyfit(zu,mA,2);
xo = zu(1);
yo = mA(1);%1.05;
n = 2;
Aeq = xo.^(n:-1:0);
beq = yo;
% 
% Aeq = [];
% beq = [];
V = [];C = [];
V (:,n+1) = ones(length(zu), 1, class(zu));
for jx = n:-1:1, V(:, jx) = zu(:).*V(:, jx+1);end
C = V;
mA = mA(:);
p = lsqlin(C,mA,[],[],Aeq, beq);
FitMeanAreas = polyval(p, zu);
plot(zu,mA);hold on;plot(zu, FitMeanAreas, 'r-');



% p = polyfit(zu,mA,2);
% fac = polyval(p, zu);
% plot(zu,mA);hold on;plot(zu, fac);
% %
% cc = counts(1:2:end,:);
% % plot results
% hf = figure;
% ha = axes;
% hb = bar3(edges, cc.'); % note the transpose to get the colors right
% xlabel('case number')
% ylabel('bins');
% zlabel('count');