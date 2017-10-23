function [L_s_mL] = place_components(L_vec, L_s_mL)
%% rotate and translate components to be as close as possible to L_vec (or opts.rc

% center L_s_mL(1) tiles around center of mass
%%% calculate center of mass of this connected component
tmr = zeros(numel(L_s_mL(1).tiles),2);
for tix = 1:numel(L_s_mL(1).tiles)
    tmr(tix,:) = L_s_mL(1).tiles(tix).tform.T([3 6]);
end
cm = sum(tmr)/size(tmr,1);

for tix = 1:numel(L_s_mL(1).tiles)
    T = L_s_mL(1).tiles(tix).tform.T;
    T([3 6]) = T([3 6])-cm;
    L_s_mL(1).tiles(tix).tform.T = T;
end
%%%%%%%%%%%%%%%%%     
if isfield(opts, 'base_collection') && ~isempty(opts.base_collection)
    [tileso, tIds] = get_reference_tiles(opts.base_collection, min(zC{1}), max(zC{1}));
else
    tileso = L_vec(1).tiles; % tiles from unregistered main components
end
tiles = L_s_mL(1).tiles; % tiles of registered main component
% pick random tiles from main component for each z value
nr = 3; % number of reference tiles to use per z value from the main component
indxr = zeros(numel(zC{1}), nr); % store random tiles used
xro = zeros(numel(zC{1}), nr); % store x position of random tiles
yro = zeros(numel(zC{1}), nr);

xr = zeros(numel(zC{1}), nr); % store x position of random tiles
yr = zeros(numel(zC{1}), nr);

for ix = 1:numel(zC{1})  % loop over valid z values for main component
    indxr(ix,:) = randi(numel(find([tiles(:).z]==zC{1}(ix))), 1,nr);
    for tix = 1:nr
        xro(ix, tix) = tileso(indxr(ix, tix)).tform.T(3);
        yro(ix, tix) = tileso(indxr(ix, tix)).tform.T(6);
        
        xr(ix, tix) = tiles(indxr(ix, tix)).tform.T(3);
        yr(ix, tix) = tiles(indxr(ix, tix)).tform.T(6);
    end
end

% center of mass of each section of main component before registration
cmro = zeros(numel(zC{1}),2);
for lix = 1:numel(zC{1})
    indx = find([L_vec(1).tiles(:).z]==zC{1}(lix));
    tmr = [];
    for tix = 1:numel(indx)
        tmr(tix,:) = L_vec(1).tiles(indx(tix)).tform.T([3 6]);
    end
    cmro(lix,:) = sum(tmr)/size(tmr,1);
end

% center of mass of each section of main component after registration
cmr = zeros(numel(zC{1}),2);
for lix = 1:numel(zC{1})
    indx = find([L_s_mL(1).tiles(:).z]==zC{1}(lix));
    tmr = [];
    for tix = 1:numel(indx)
        tmr(tix,:) = L_s_mL(1).tiles(indx(tix)).tform.T([3 6]);
    end
    cmr(lix,:) = sum(tmr)/size(tmr,1);
end


L_s_mL(1) = get_bounding_box(L_s_mL(1)); % minx maxx miny maxy
box = L_s_mL(1).box;

%%%% sosi --- look at result cartoons
Lro = split_z(L_vec(1));
Lr = split_z(L_s_mL(1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for cix = 2:numel(L_vec)  % loop over components other than first (main)
    %disp(['Processing: ' num2str(cix) ' with #tiles: ' num2str(numel(L_vec(cix).tiles))]);
    if numel(L_vec(cix).tiles)>opts.min_tiles
        if stvec_flag==0
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % RECOVER POSSIBLE ROTATION AND TRANSLATION RELATIVE TO REFERENCE %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            L = L_s_mL(cix); % current component
            %%% calculate center of mass of this connected component
            tmr = zeros(numel(L.tiles),2);
            for tix = 1:numel(L.tiles)
                tmr(tix,:) = L.tiles(tix).tform.T([3 6]);
            end
            cm = sum(tmr)/size(tmr,1);
            % center around its center of mass;
            for tix = 1:numel(L(1).tiles)
                T = L(1).tiles(tix).tform.T;
                T([3 6]) = T([3 6])-cm;
                L(1).tiles(tix).tform.T = T;
            end
            tmr = zeros(numel(L.tiles),2);
            for tix = 1:numel(L.tiles)
                tmr(tix,:) = L.tiles(tix).tform.T([3 6]);
            end
            cm = sum(tmr)/size(tmr,1);
            %%%%%%%%%%%%%
            
            dref = tile_distances(L, zC{1}, xr, yr); % in-plane distance between tiles and main component
            dref = tile_distances(L_vec(cix), zC{1}, xro, yro);% calculate reference distances, i.e. between L_vec(cix) and unregistered main component
%             dcurr = tile_distances(L_s_mL(cix), zC, xr, yr);
%             res = obj_fun([0 -0 0]);

            
            optim_options = optimoptions('lsqnonlin');
            %optim_options.Algorithm = 'levenberg-marquardt';
            optim_options.MaxFunctionEvaluations = 10000;
            optim_options.MaxIterations = 1000;
            optim_options.FunctionTolerance = 1e-16;
            optim_options.Display = 'iter';%'none';
            lb = [0 box(1)-5000 box(3)-5000];
            ub = [180 box(2)+5000 box(4)-5000];
%             [x, res] = lsqnonlin(@obj_fun, [0 cmr(1)-cm(1) cmr(2)-cm(2)], lb, ub, optim_options);
            [x, res] = lsqnonlin(@obj_fun, [0 0 0], lb, ub, optim_options);
            disp(['Residual: ' num2str(res)]);
            
            
            
            % apply result to tiles
            for tix = 1:numel(L_s_mL(cix).tiles)
                L_s_mL(cix).tiles(tix) = rotate(L_s_mL(cix).tiles(tix), cm(1), cm(2), x(1));
            end
            for tix = 1:numel(L.tiles)
                L_s_mL(cix).tiles((tix)).tform.T([3 6]) = L_s_mL(cix).tiles((tix)).tform.T([3 6])  + [x(2) x(3)];
            end
            
            %%% sosi --- look at result cartoons
            zreq = 23;
            Ls = split_z(L_s_mL(cix));
            ns = find([Ls(:).z]==zreq);
            nr = find([Lr(:).z]==zreq);
            figure(1);clf;show_map(Lr(nr));hold on;show_map(Ls(ns));
            
            
            Ls = split_z(L_vec(cix));
            ns = find([Ls(:).z]==zreq);
            nr = find([Lro(:).z]==zreq);
            figure(2);clf;show_map(Lro(nr));hold on;show_map(Ls(ns));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
        end
    end
end


%%
mL = concatenate_tiles(L_s_mL, opts.outlier_lambda);

%%
function res = obj_fun(x)
global L dref zC xr yr cm
Ltry = L;

%%% rotate all tiles around this center of mass using the average
%%% angle da
for tix = 1:numel(Ltry.tiles)
    Ltry.tiles(tix) = rotate(Ltry.tiles(tix), cm(1), cm(2), x(1));
end
for tix = 1:numel(L.tiles)
    Ltry.tiles((tix)).tform.T([3 6]) = Ltry.tiles((tix)).tform.T([3 6])  + [x(2) x(3)];
end
dcurr = tile_distances(Ltry, zC{1}, xr, yr);
res = -dref(:) - dcurr(:);
%% 
function dcurr = tile_distances(Lcurr, zC, xr, yr)
% calculate current distances
% Lcurr = L_s_mL(cix);
nr = size(xr,2);
dcurr = zeros(numel(Lcurr.tiles), nr); % store distances
for tix =  1%:numel(Lcurr.tiles)
    z_curr = Lcurr.tiles(tix).z;
    indxz = find(zC==z_curr);
    x1 = Lcurr.tiles(tix).tform.T(3) * ones(1,nr);
    y1 = Lcurr.tiles(tix).tform.T(6) * ones(1,nr);
    dcurr(tix,:) = sqrt((x1-xr(indxz,:)).^2 + (y1-yr(indxz,:)).^2 );
end

%% 
function [tiles, tIds] = get_reference_tiles(rc, nfirst, nlast)
%% get the list of zvalues and section ids within the z range between nfirst and nlast (inclusive)
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/sectionData', ...
    rc.baseURL, rc.owner, rc.project, rc.stack);
js = webread(urlChar);
[z, ia]   = sort(([js(:).z]));
indx = find(z>=nfirst & z<=nlast);
z         = z(indx);        % determine the zvalues (this is also the spatial order)
[zu, ia, ic] = unique(z);% we need unique values, 

options = weboptions;
options.Timeout = 20;
clear t;
for ix = 1:numel(zu)
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack, zu(ix));
    j = webread(urlChar, options);
    jt = tile;
    for jix = 1:numel(j)
        jt(jix) = tile(j(jix));
        jt(jix).z = zu(ix);
    end
    t(ix).jt = jt;
end

% concatenate all tile ids
tIds = {};
tiles = [];
for ix = 1:numel(zu)
    tIds = [tIds {t(ix).jt.renderer_id}];
    tiles = [tiles t(ix).jt];
end

% loop over tiles to set tile id
parfor ix = 1:numel(tiles)
    tiles(ix).id = ix;
end