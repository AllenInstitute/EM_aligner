function ApplyLowResToHighRes(L, rcmontage, rcfine, rcrough, pm, opts, first, last)

%% This code assumes that the lowres_stack is created without the scale factor added to it

L3s = split_z(L);

[zu,sID, sectionsId, z, ns] = get_section_ids(rcmontage, first, last);

parfor zix = 1:numel(zu)
  L_montage(zix) = Msection(rcmontage, zu(zix));
end

for lix = 1:numel(L_montage)
  % compute the section bounding box
  L_montage(lix) = get_bounding_box(L_montage(lix));
end

L.update_tile_info_switch = -1;
% get stack bounds of the lowres_stack
L = get_bounding_box(L);
wbox = [L.box(1) L.box(3) L.box(2)-L.box(1) L.box(4)-L.box(3)];
wb1 = wbox(1);
wb2 = wbox(2);

fac = pm.scale;
smx = [fac 0 0; 0 fac 0; 0 0 1];
invsmx = [1/fac 0 0; 0 1/fac 0; 0 0 1];
tmx2 = [1 0 0; 0 1 0; -wb1 -wb2 1];
L3T = cell(numel(L_montage),1);

for lix = 1:numel(L_montage)
  L3T{lix} = L3s(lix).tiles(1).tform.T;
end

parfor lix = 1:numel(L_montage)
  b1 = L_montage(lix).box;
  dx = b1(1); dy = b1(3);
  tmx1 = [1 0 0; 0 1 0; -dx -dy 1];

  tiles = L_montage(lix).tiles;
  T3 = L3T{lix};
  for tix = 1:numel(L_montage(lix).tiles)
    newT = tiles(tix).tform.T * tmx1 * smx * T3 * tmx2 * (invsmx);
    tiles(tix).tform.T = newT;
  end
  [x1,y1] = get_tile_centers_tile_array(tiles);
  L_montage(lix).tiles = tiles;
  L_montage(lix).X = x1;
  L_montage(lix).Y = y1;
end

opts.outlier_lambda = 1e3;
L_montage = concatenate_tiles(L_montage);

%% ingest into render database
opts.disableValidation = 1;
ntiles = numel(L_montage.tiles);
Tout = zeros(ntiles, 6);
tiles = L_montage.tiles;

for tix = 1:ntiles
  Tout(tix,:) = tiles(tix).tform.T(1:6)';
end

tIds = cell(ntiles,1);
for tix = 1:ntiles
  tIds{tix} = L_montage.tiles(tix).renderer_id;
end

z_val = zeros(ntiles,1);
for tix = 1:ntiles
  z_val(tix) = L_montage.tiles(tix).z;
end


delta = 0;
dx = min(Tout(:,3)) + delta;
dy = min(Tout(:,6)) + delta;

for ix = 1:size(Tout,1)
  Tout(ix,[3 6]) = Tout(ix, [3 6]) - [dx dy];
end

v = 'v1';

if ~stack_exists(rcfine)
  resp = create_renderer_stack(rcfine);
end

if ~stack_loading(rcfine)
  resp = set_renderer_stack_state_loading(rcfine);
end

chks = round(ntiles/128);
cs = 1:chks:ntiles;
cs(end) = ntiles;

parfor ix = 1:numel(cs)-1
  vec = cs(ix):cs(ix+1);
  export_to_renderer_database(rcfine, rcmontage, pwd, Tout(vec,:), ...
        tIds(vec), z_val(vec), v, opts.disableValidation);
end

resp = set_renderer_stack_state_complete(rcfine);
