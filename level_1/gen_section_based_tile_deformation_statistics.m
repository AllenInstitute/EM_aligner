function [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec, Resx,Resy] =...
    gen_section_based_tile_deformation_statistics(rc, zstart, zend, pm, opts)
%%%% deprecated ---- please use "gen_slab_diagnostics.m" instead
%% generate statistics about residuals and tile deformation
% Summarizes point-match residuals and tile deformation per tile and section taking
% into accounts its neighbors.
% opts fields and their defaults:
%    min_points     : 5
%    nbrs           : 4
%
% Output:
%       mA, mS
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4
% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

end
if nargin<5
opts.min_points = 5;
opts.nbrs = 4;
end


[zu1, sID1, sectionId1, z1, ns1] = get_section_ids(rc, zstart, zend);

%% find corresponding tile centers
tic
% initialize variables to store deformation and residuals
confidence  = cell(numel(zu1),1);
sctn_map  = cell(numel(zu1),1);
tile_areas = cell(numel(zu1),1);
tile_perimeters = cell(numel(zu1),1);
tidsvec = cell(numel(zu1),1);
Resx = cell(numel(zu1),1);
Resy = cell(numel(zu1),1);
% to generate histogram counts we need to define bin edges
edges = [0.4:.02:1.7];
counts = zeros(numel(zu1), numel(edges));   
webopts = weboptions('Timeout', 60);
parfor zix = 1:numel(zu1)
    %disp(zu1(zix));
    Ar = [];    % surface area of tiles
    Aratio = [];% surface area ratio of tiles
    S  = [];    % perimeter of tiles
    p = [];     % tile patch
    % call the Renderer API to fetch tile information
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack,zu1(zix) );

    j = webread(urlChar, webopts);
    
    % process individual tiles
    jt1 = tile;
    sectionID = j(1).layout.sectionId;
    count = 1;
    tids = {};
    for jix = 1:numel(j)
        jt1(jix) = tile(j(jix));
        tids(jix) = {jt1(jix).renderer_id};
        % make four corners for this tile
        x = 0;
        y = 0;
        Px = [x; x + jt1(jix).W; x + jt1(jix).W; x];
        Py = [y; y    ; y + jt1(jix).H; jt1(jix).H];
        %%% transform points
        if strcmp(class(jt1(jix).tform), 'affine2d')
            P = [Px(:) Py(:) [1 1 1 1]']*jt1(jix).tform.T;
        else
            P = transformPointsInverse(jt1(jix).tform,[Px Py]);
        end
        p{jix} = {P};
        %cm(jix,:) = sum([P(:,1)/4 P(:,2)/4],1);  % center of mass of each tile
        
        
        % check polygon area
        Ar(count) = polyarea(P(:,1), P(:,2));
        Aratio(count) = Ar(count)/(jt1(jix).H * jt1(jix).W);
        
        %%% polygonperimeter
        s = 0;
        s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
        s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
        s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
        s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
        S(count) = s;
        
        
        count = count + 1;
    end
    tidsvec{zix} = tids;
    counts(zix,:) = histc(Aratio, edges, 2);
    tile_areas{zix} = Ar;
    tile_perimeters{zix} = S;
    mA(zix) = median(Aratio);
    mS(zix) = median(S);
    sctn_map{zix} = p;
    %% %%% determine point-matches, solution and residuals for this section
    
    
    % First: load point-matches and section into "L" (point-matches are in L's pm struct field)
    if (zix + opts.nbrs)>numel(zu1)
        pmz2 = zu1(end);
    else
        pmz2 = zu1(zix + opts.nbrs);
    end
    [L]  = ...
        load_point_matches(zu1(zix), pmz2, rc, pm, opts.nbrs, ...
        opts.min_points, 0);
    
    % initialize variable tpr to hold point-match residuals
    tpr = cell(numel(L.tiles),1);   % tpr === transformed point-match residuals
    % initialize tpr
    for tix = 1:numel(L.tiles)
        tpr{tix} = [];
    end
    
    % generate point-match residuals from L.pm by transforming them and taking the sum of squared
    % residuals
    res_vecx = [];
    res_vecy = [];
    for pmix = 1:size(L.pm.M,1)
        a1 = L.pm.adj(pmix,1);
        a2 = L.pm.adj(pmix,2);
        m1 = L.pm.M{pmix,1};
        m2 = L.pm.M{pmix,2};
        m1 = [m1 ones(size(m1,1),1)]*L.tiles(a1).tform.T;  % apply transformation
        m2 = [m2 ones(size(m2,1),1)]*L.tiles(a2).tform.T;  % apply transformation
        res = sum((m1-m2).^2);    %%%% sum of squared residuals
        %disp(res);
        %res_vec(pmix,:) = sqrt((m1(1)-m2(1))*(m1(1)-m2(1)) + (m1(1)-m2(1))*(m1(2)-m2(2)));
        
        %%%% sosi
        res_vecx(pmix,:) = abs(m1(1)-m2(1));
        res_vecy(pmix,:) = abs(m1(2)-m2(2));
        
        tpr{a1} = [tpr{a1};res(1:2)];
        tpr{a2} = [tpr{a2};res(1:2)];
    end
    Resx{zix} = res_vecx;
    Resy{zix} = res_vecy;
    % store errors/confidence in cell array "confidence"
    for tix = 1:numel(L.tiles)
        if isempty(tpr{tix})
            confidence{zix} = {[]};
        else
            confidence{zix} = tpr;%{sum(tpr{tix},1)/size(tpr{tix},1)};
        end
    end
    
end
toc
Resx = cell2mat(Resx);
Resy = cell2mat(Resy);
%%

figure;plot(zu1, mA, '-o', 'LineWidth',2);title(['Area median per layer: ' num2str(zstart) ' to ' num2str(zend)]);
%figure;plot(zu1, mS, 'LineWidth',2);title('Perimeter median perlayer');

title(rc.stack);

figure; hist(real(Resx)); title([rc.stack ' -- Resx']);
figure; hist(real(Resy)); title([rc.stack ' -- Resy']);

%% display
if dopts.show_deformation
    % c = [];
    Ao = 2560*2160;
    colormap jet;
    for zix = 1:numel(zu1)
        figure;
        sm = sctn_map{zix};
        areas = tile_areas{zix}/Ao;
        %caxis([min(areas) max(areas)]);
        c = mat2gray(areas, [min(areas) max(areas)]);
        
        for tix = 1:numel(sm)
            P = sm{tix}{1};   % patch for this tile
            patch( P(:,1), P(:,2), [c(tix)],'FaceColor', 'flat',   'EdgeColor', 'k' , 'Facealpha', 0.4);
        end
        daspect([1 1 1]);colorbar; axis ij
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analyze results
% zconf = [];
% for zix = 1:1%numel(zu1)
%     c = confidence{zix};
%     t = tidsvec{zix};
%     for tix = 1:size(c,1)
%         if isempty(c{tix})
%             zconf(tix,:) = [nan nan];
%         else
%             zconf(tix,:) = [sum(c{tix},1)/size(c{tix},1)];
%         end
%         disp([num2str(zix) ' '  num2str(tix) ' ' t{tix} '  ' num2str(zconf(tix,:))]);
%     end
% end

%[obj, h, rh, A, minconf, maxconf] = show_map_color(obj, parm, conf,  minconf, maxconf);

%% look at section map
% c = [];
% Ao = 2560*2160;
% colormap jet;
% for zix = 45:45 %numel(zu1)
%     %figure;
%     sm = sctn_map{zix};
%     areas = tile_areas{zix}/Ao;
%     %caxis([min(areas) max(areas)]);
%     c = mat2gray(areas, [min(areas) max(areas)]);
%     
%     for tix = 1:numel(sm)
%         P = sm{tix}{1};   % patch for this tile
%         patch( P(:,1), P(:,2), [c(tix)],'FaceColor', 'flat',   'EdgeColor', 'k' , 'Facealpha', 0.4);
%     end
%     daspect([1 1 1]);colorbar; axis ij
% end

%%
% zu = zu1;
% % p = polyfit(zu,mA,2);
% xo = 1;
% yo = 1.05;
% n = 2;
% Aeq = xo.^(n:-1:0);
% beq = yo;
% %
% % Aeq = [];
% % beq = [];
% V = [];C = [];
% V (:,n+1) = ones(length(zu), 1, class(zu));
% for jx = n:-1:1, V(:, jx) = zu(:).*V(:, jx+1);end
% C = V;
% mA = mA(:);
% p = lsqlin(C,mA,[],[],Aeq, beq);
% fac = polyval(p, zu);
% plot(zu,mA);hold on;plot(zu, fac);
%
%
%
%
%
%
%
%%
% cc = counts(1:5:end,:);
% % plot results
% hf = figure;
% ha = axes;
% b = bar3(edges, cc.'); % note the transpose to get the colors right
% xlabel('case number')
% ylabel('bins');
% zlabel('count');
% 
% 
% for k = 1:length(b)
%     zdata = b(k).ZData;
%     b(k).CData = zdata;
%     b(k).FaceColor = 'interp';
% end
% 
% view(2);















