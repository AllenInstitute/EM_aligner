%% generate area deformation graphs
zstart = 1;
zend = 7062;

rcv12.stack          = 'v12_align';
rcv12.owner          ='flyTEM';
rcv12.project        = 'FAFB00';
rcv12.service_host   = '10.40.3.162:8080';
rcv12.baseURL        = ['http://' rcv12.service_host '/render-ws/v1'];
rcv12.verbose        = 1;
%
rc5.stack          = 'FULL_FAFB_FUSED_05';
rc5.owner          ='flyTEM';
rc5.project        = 'test2';
rc5.service_host   = '10.40.3.162:8080';
rc5.baseURL        = ['http://' rc5.service_host '/render-ws/v1'];
rc5.verbose        = 1;

pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

%%
kk_clock;
[mA12, mS12, sctn_map12, confidence12, tile_areas12, tile_perimeters12, tidsvec12] =...
    gen_section_based_tile_deformation_statistics(rcv12, zstart, zend, pm);
figure;
kk_clock;
[mA5, mS5, sctn_map5, confidence5, tile_areas5, tile_perimeters5, tidsvec5] =...
    gen_section_based_tile_deformation_statistics(rc5, zstart, zend, pm);
kk_clock;