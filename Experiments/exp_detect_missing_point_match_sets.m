%%% detect missing or small potential point-match sets for a montage based
%%% on spatial proximity
nfirst = 3813;
nlast  = 3813;
rc.stack          = ['v14_montage'];
rc.owner          ='flyTEM';
rc.project        = 'FAFB00';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'FAFB_pm_4';

nbr = 0;
min_points = 0;
xs_weight = 1;
max_points = inf;


[L, tIds, PM] = load_point_matches(nfirst, ...
    nlast, rc, pm, nbr, min_points, xs_weight, max_points);
L.pm = filter_pm(L.pm);
%%%% sosi
show_point_matches(L);

L = Msection(sl.source_collection, sl.section_number);   % instantiate Msection object using the Renderer service to read tiles

[x1, y1, tids, L1, cm] = get_tile_centers(rc, z, plot_flag);