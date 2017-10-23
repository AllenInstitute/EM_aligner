%%%% test fix_section_pair_alignment
rc_base.stack          = 'v12_acquire_merged';
rc_base.owner          ='flyTEM';
rc_base.project        = 'FAFB00';
rc_base.service_host   = '10.37.5.60:8080';
rc_base.baseURL        = ['http://' rc_base.service_host '/render-ws/v1'];
rc_base.verbose        = 1;

% configure montage collection
rc.stack          = ['EXP_dmesh_rough_P1_1_35'];
rc.owner          ='flyTEM';
rc.project        = 'test';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

%%
z1 = 32;
z2 = 33;
scale = 0.1;
fix_section_pair_alignment(rc, rc_base, z1,z2, scale);