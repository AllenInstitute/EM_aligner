%% generate statistics about residuals and tile area and pixel dimensions
function [zu1, confidence, tidsvec, sctn_map, tile_areas, tile_perimeters, mA, mS, zresid, counts] = generate_diagnostic_data(rc, zstart, zend, pm, opts)
    [zu1, ~, ~, ~, ~] = get_section_ids(rc, zstart, zend);

    % initialize variables to store deformation and residuals
    confidence  = cell(numel(zu1),1);
    sctn_map  = cell(numel(zu1),1);
    tile_areas = cell(numel(zu1),1);
    tile_perimeters = cell(numel(zu1),1);
    tidsvec = cell(numel(zu1),1);
    zresid = cell(numel(zu1), 1);
    mA = zeros(numel(zu1), 1);
    mS = zeros(numel(zu1), 1);

    % to generate histogram counts we need to define bin edges
    edges = [1:.01:2];
    counts = zeros(numel(zu1), numel(edges));
    
    opts_nbrs = opts.nbrs;
    opts_min_points = opts.min_points;

    rc_base_url = rc.baseURL;
    rc_owner = rc.owner;
    rc_project = rc.project;
    rc_stack = rc.stack;
    
    %% find corresponding tile centers
    parfor zix = 1:numel(zu1)
        disp(zu1(zix));
        % call the Renderer API to fetch tile information
        urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
            rc_base_url, rc_owner, rc_project, rc_stack, zu1(zix) );
        wo = weboptions('Timeout', 60)
        j = webread(urlChar, wo);

        % process individual tiles
        jt1 = tile;

        Ar = zeros(numel(j), 1);     % surface area of tiles
        Aratio = zeros(1, numel(j)); % surface area ratio of tiles
        S  = zeros(numel(j), 1);     % perimeter of tiles
        p = cell(numel(j), 1);       % tile patch
        tids = cell(numel(j), 1);    % tile IDs
        for jix = 1:numel(j)
            jt1(jix) = tile(j(jix));
            tids(jix) = {jt1(jix).renderer_id};
            % make four corners for this tile
            x = 0;
            y = 0;
            Px = [x; x + jt1(jix).W; x + jt1(jix).W; x];
            Py = [y; y    ; y + jt1(jix).H; jt1(jix).H];
            %%% transform points
            if isa(jt1(jix).tform, 'affine2d')
                P = [Px(:) Py(:) [1 1 1 1]']*jt1(jix).tform.T;
            else
                P = transformPointsInverse(jt1(jix).tform,[Px Py]);
            end
            p{jix} = {P};

            % check polygon area
            Ar(jix) = polyarea(P(:,1), P(:,2));
            Aratio(jix) = Ar(jix)/(jt1(jix).H * jt1(jix).W);

            %%% polygonperimeter
            s = 0;
            s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
            s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
            s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
            s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
            S(jix) = s;
        end
        tidsvec{zix} = tids;
        counts(zix,:) = histc(Aratio, edges, 2);
        tile_areas{zix} = Ar;
        tile_perimeters{zix} = S;
        mA(zix) = median(Aratio);
        mS(zix) = median(S)
        sctn_map{zix} = p;

        %% %%% determine point-matches, solution and residuals for this section

        % First: load point-matches and sectionn into "L" (point-matches are in L's pm struct field)
        [L] = load_point_matches(zu1(zix), zu1(zix), rc, pm, opts_nbrs, opts_min_points, 0);

        % initialize variable tpr to hold point-match residuals
        tpr = cell(numel(L.tiles), 1);   % tpr === transformed point-match residuals
        % initialize tpr
        for tix = 1:numel(L.tiles)
            tpr{tix} = [];
        end

        % generate point-match residuals from L.pm by transforming them and taking the sum of squared
        % residuals
        for pmix = 1:size(L.pm.M,1)
            a1 = L.pm.adj(pmix,1);
            a2 = L.pm.adj(pmix,2);
            m1 = L.pm.M{pmix,1};
            m2 = L.pm.M{pmix,2};
            m1 = [m1 ones(size(m1,1),1)]*L.tiles(a1).tform.T;  % apply transformation
            m2 = [m2 ones(size(m2,1),1)]*L.tiles(a2).tform.T;  % apply transformation
            res = sum((m1-m2).^2);    %%%% sum of squared residuals
            tpr{a1} = [tpr{a1};res(1:2)];
            tpr{a2} = [tpr{a2};res(1:2)];
        end
        
        % store errors/confidence in cell array "confidence"
        for tix = 1:numel(L.tiles)
            if isempty(tpr{tix})
                confidence{zix} = {[]};
                zresid{zix}(tix,:) = nan;
            else
                confidence{zix} = tpr;
                zresid{zix}(tix,:) = sum(sqrt(sum(tpr{tix},2)))/size(tpr{tix},1);
            end
        end
    end % end for zix
end
