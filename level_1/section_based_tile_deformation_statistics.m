%% generate statistics about residuals and tile and pixel dimensions


zstart = 1;
zend = 13;

% configure base collection (unregistered)
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.40.3.162:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;



% rc.stack          = ['PROD_FINE_MP1_RR_P1_' num2str(zstart) '_' num2str(zend) '_xs_2'];
% rc.owner          ='flyTEM';
% rc.project        = 'test2';
% rc.service_host   = '10.40.3.162:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;

% configure fixed collection
rc.stack          = ['FULL_FAFB_FUSED_03'];
rc.owner          ='flyTEM';
rc.project        = 'test2';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;





pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';


% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 4;
opts.xs_weight = 1;
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 1;
%%%%%
opts.lambda = 10^(-2);
opts.edge_lambda = 10^(-2);


[zu1, sID1, sectionId1, z1, ns1] = get_section_ids(rc, zstart, zend);

%% find corresponding tile centers
tic
confidence  = cell(numel(zu1),1);
tidsvec = cell(numel(zu1),1);
edges = [1:.01:2];
counts = zeros(numel(zu1), numel(edges));
parfor zix = 1:numel(zu1)
    disp(zix);
    Ar = [];
    Aratio = [];
    S  = [];
    
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack,zu1(zix) );
    j = webread(urlChar);
    jt1 = tile;
    sectionID = j(1).layout.sectionId;
    count = 1;
    tids = {};
    for jix = 1:numel(j)
        jt1(jix) = tile(j(jix));
        tids(jix) = {jt1(jix).renderer_id};
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
        % add polygonperimeter
        %         s = 0;
        %         s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
        %         s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
        %         s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
        %         s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
        %         S(zix, count) = s;
        count = count + 1;
    end
    tidsvec{zix} = tids;
    counts(zix,:) = histc(Aratio, edges, 2);
    mA(zix) = mean(Aratio);
    
    %% determine point-matches, solution and residuals for this section
    [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
        load_point_matches(zu1(zix), zu1(zix), rc, pm, opts.nbrs, ...
        opts.min_points, 0);
    
    %% collect residuals
    tpr = cell(numel(L.tiles),1);
    % initialize
    for tix = 1:numel(L.tiles)
        tpr{tix} = [];
    end
    for pmix = 1:size(L.pm.M,1)
        a1 = L.pm.adj(pmix,1);
        a2 = L.pm.adj(pmix,2);
        m1 = L.pm.M{pmix,1};
        m2 = L.pm.M{pmix,2};
        m1 = [m1 ones(size(m1,1),1)]*L.tiles(a1).tform.T;
        m2 = [m2 ones(size(m2,1),1)]*L.tiles(a2).tform.T;
        res = sum((m1-m2).^2);
        tpr{a1} = [tpr{a1};res(1:2)];
        tpr{a2} = [tpr{a2};res(1:2)];
    end
    % average the error
    for tix = 1:numel(L.tiles)
        
        if isempty(tpr{tix})
            confidence{zix} = {[]};
        else
            confidence{zix} = tpr;%{sum(tpr{tix},1)/size(tpr{tix},1)};
        end
    end
    
end
toc
%% analyze results
zconf = [];
for zix = 1:1%numel(zu1)
    c = confidence{zix};
    t = tidsvec{zix};
    for tix = 1:size(c,1)
        if isempty(c{tix})
            zconf(tix,:) = [nan nan];
        else
            zconf(tix,:) = [sum(c{tix},1)/size(c{tix},1)];
        end
        disp(zconf);
    end
end

%[obj, h, rh, A, minconf, maxconf] = show_map_color(obj, parm, conf,  minconf, maxconf);

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
% %%
% cc = counts(1:2:end,:);
% % plot results
% hf = figure;
% ha = axes;
% hb = bar3(edges, cc.'); % note the transpose to get the colors right
% xlabel('case number')
% ylabel('bins');
% zlabel('count');




















