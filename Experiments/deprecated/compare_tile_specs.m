% scrap space

kk_clock;


nfirst = 11;
nlast  = 16;
% configure rough collection
rc.stack          = 'v12_acquire_LC';
rc.owner          ='flyTEM';
rc.project        = 'FAFB00';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';


% nfirst = 1;
% nlast  = 4;
% % configure rough collection
% rc.stack          = ['EXP_v12_rough_' num2str(nfirst) '_' num2str(nlast)];
% rc.owner          ='flyTEM';
% rc.project        = 'test';
% rc.service_host   = '10.37.5.60:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
% 
% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'FAFBv12Test18';



% configure point match fetching
opts.min_points = 10;
opts.nbrs = 3;
opts.xs_weight = 1/100;
opts.stvec_flag = 1;   % i.e. do not assume rcsource providing the starting values.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[L, tIds, PM, pm_mx, sectionIds, zvals] = check_pm_data(nfirst, nlast, rc, pm, opts);
L = split_z(L);



nT = 1;
t11 = L(1).tiles(5);disp(t11.renderer_id);js1 = get_tile_spec_renderer(t11);disp(js1.tileSpecs.transforms.specList(nT))
t12 = L(2).tiles(5);disp(t12.renderer_id);js2 = get_tile_spec_renderer(t12);disp(js2.tileSpecs.transforms.specList(nT))
t13 = L(3).tiles(5);disp(t13.renderer_id);js3 = get_tile_spec_renderer(t13);disp(js3.tileSpecs.transforms.specList(nT))
t14 = L(4).tiles(5);disp(t14.renderer_id);js4 = get_tile_spec_renderer(t14);disp(js4.tileSpecs.transforms.specList(nT))
t15 = L(5).tiles(5);disp(t15.renderer_id);js5 = get_tile_spec_renderer(t15);disp(js5.tileSpecs.transforms.specList(nT))
t16 = L(6).tiles(5);disp(t16.renderer_id);js6 = get_tile_spec_renderer(t16);disp(js6.tileSpecs.transforms.specList(nT))


