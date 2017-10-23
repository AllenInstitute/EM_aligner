%%%%%%%%%%%%% debug scritp for world-to-local coordinates

L(1).tiles(1)
t1 = ans;
L_montaged(1).tiles(1);
t1m = L_montaged(1).tiles(1);
t1.renderer_id
t1m.renderer_id
t1.tform.T(:)'
t1m.tform.T(:)'
v = get_tile_spec_renderer(t1)
v = get_tile_spec_renderer(t1m)
v = get_tile_spec_renderer(t1);disp(v.tileSpecs)
v = get_tile_spec_renderer(t1);disp(v.tileSpecs.transforms)
v = get_tile_spec_renderer(t1);disp(v.tileSpecs.transforms.specList)
v = get_tile_spec_renderer(t1);disp(v.tileSpecs.transforms.specList(1))
v = get_tile_spec_renderer(t1);disp(v.tileSpecs.transforms.specList(2))
v = get_tile_spec_renderer(t1);disp(v.tileSpecs.transforms.specList(3))
v = get_tile_spec_renderer(t1);disp(v.tileSpecs.transforms.specList(4))
v = get_tile_spec_renderer(t1m);disp(v.tileSpecs.transforms.specList(4))
v = get_tile_spec_renderer(t1m);disp(v.tileSpecs.transforms.specList(3))
t1m.tform.T(:)'
t1.tform.T(:)'
t1r = L_rough(1).tiles(1)
t1.renderer_id
t1m.renderer_id
t1r.renderer_id
v = get_tile_spec_renderer(t1r);disp(v.tileSpecs.transforms.specList(4))
t1r.tform.T(:)'
v = get_tile_spec_renderer(t1r);disp(v.tileSpecs.transforms.specList)
v = get_tile_spec_renderer(t1r);disp(v.tileSpecs.transforms.specList(3))
v = get_tile_spec_renderer(t1r);disp(v.tileSpecs.transforms.specList(2))
v = get_tile_spec_renderer(t1m);disp(v.tileSpecs.transforms.specList(2))