function  [mA, mS, sctn_map, tile_areas, tile_perimeters, tidsvec]  = ...
    filter_deformed_tiles(rc, rc_source, rcout, zstart, zend, dir_scratch, mA_thresh)
%%  determines the deformed set based on rc
%  generates a filtered collection rcout based on collection rc_source 
%  (which can also be set the same as rc)  

[zu1, sID1, sectionId1, z1, ns1] = get_section_ids(rc, zstart, zend);

%% find corresponding tile centers
% initialize variables to store deformation and residuals
sctn_map  = cell(numel(zu1),1);
tile_areas = cell(numel(zu1),1);
tile_perimeters = cell(numel(zu1),1);
tidsvec = cell(numel(zu1),1);
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
    
    %%%  delete deformed tiles
    
    medianA = median(tile_areas{zix});
    Areas = tile_areas{zix}/medianA;
    hist(Areas, 100);drawnow;
    
    %%% determine which tiles to delete
    tileids = tidsvec{zix};
    indx = find(abs(Areas)>1 + mA_thresh);
    tiles_to_delete = tileids(indx);
    
    % load all tiles  --- use fast method without Msection object
    [zu, sID, sectionId, z, ns] = get_section_ids(rc_source, zu1(zix), zu1(zix));
    [T, map_id, tIds, section_id] = load_all_transformations(rc_source, zu, dir_scratch);
    %%% remove all tiles in tiles_to_delete
    del_tiles_ix = [];
    for tix = 1:numel(tiles_to_delete)
        del_tiles_ix(tix) = map_id(tiles_to_delete{tix});
    end
    disp(['----------- Removing ' num2str(numel(del_tiles_ix)) ' from section  ' num2str(zu1(zix))]);
    T(del_tiles_ix,:) = [];  % remove unwanted tiles
    tIds(del_tiles_ix) = [];
    section_id(del_tiles_ix) = [];
    Tout{zix} = T;
    tIdsout{zix} = tIds;
    section_idout{zix} = section_id;
end

for ix = 1: numel(Tout)
    disp(['Ingesting batch ' num2str(ix) ' of ' num2str(numel(Tout)) '.']);
    ingest_tiles_into_renderer_database(rc_source, rcout, Tout{ix}, dir_scratch, tIdsout{ix}, section_idout{ix});
end

% % complete stack
disp(' .... completing stack...');
resp = set_renderer_stack_state_complete(rcout);
disp('.... done!');
diary off;
%%
function ingest_tiles_into_renderer_database(rc, rcout, Tout, dir_scratch, tIds, section_id)
% rc is the source (base) collection
% rcout is the newly created collection

ntiles = size(Tout,1);

% disp('** STEP 5:   Ingesting data .....');
% disp(' ..... translate to +ve space');
% delta = 0;
% dx = min(Tout(:,3)) + delta;%mL.box(1);
% dy = min(Tout(:,6)) + delta;%mL.box(2);
% for ix = 1:size(Tout,1)
%     Tout(ix,[3 6]) = Tout(ix, [3 6]) - [dx dy];
% end

disp('... export to MET (in preparation to be ingested into the Renderer database)...');

v = 'v1';
if stack_exists(rcout)
    disp('.... collection exists');
end
if ~stack_exists(rcout)
    disp('.... creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rcout);
end

chks = round(ntiles/32);
cs = 1:chks:ntiles;
cs(end) = ntiles;
disp(' .... ingesting ....');
parfor ix = 1:numel(cs)-1
    vec = cs(ix):cs(ix+1)-1;
    export_to_renderer_database(rcout, rc, dir_scratch, Tout(vec,:),...
        tIds(vec), section_id(vec), v);
end




























