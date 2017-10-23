% test collection fusion function

clc;clear all;


% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure rough collection
rcfixed.stack          = ['EXP_FAFB_FUSED'];
rcfixed.owner          ='flyTEM';
rcfixed.project        = 'test';
rcfixed.service_host   = '10.37.5.60:8080';
rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
rcfixed.verbose        = 1;
rcfixed.nfirst         = 1;
rcfixed.nlast          = 300;

% configure rough collection
rcmoving.stack          = ['PROD_FINE_MP1_RR_P1_250_550_xs_2'];
rcmoving.owner          ='flyTEM';
rcmoving.project        = 'test2';
rcmoving.service_host   = '10.37.5.60:8080';
rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
rcmoving.verbose        = 1;
rcmoving.nfirst         = 250;
rcmoving.nlast          = 550;

% configure output collection
rcout.stack          = ['EXP_FAFB_FUSED'];
rcout.owner          ='flyTEM';
rcout.project        = 'test';
rcout.service_host   = '10.37.5.60:8080';
rcout.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
rcout.verbose        = 1;
%%
overlap = [250 300];
resp = fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout);

% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
% 
% % configure rough collection
% rcfixed.stack          = ['EXP_FAFB_FUSED'];
% rcfixed.owner          ='flyTEM';
% rcfixed.project        = 'test';
% rcfixed.service_host   = '10.37.5.60:8080';
% rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
% rcfixed.verbose        = 1;
% rcfixed.nfirst         = 1;
% rcfixed.nlast          = 150;
% 
% % configure rough collection
% rcmoving.stack          = ['PROD_FINE_MP1_RR_P1_120_300_xs_2'];
% rcmoving.owner          ='flyTEM';
% rcmoving.project        = 'test2';
% rcmoving.service_host   = '10.37.5.60:8080';
% rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcmoving.verbose        = 1;
% rcmoving.nfirst         = 120;
% rcmoving.nlast          = 300;
% 
% % configure output collection
% rcout.stack          = ['EXP_FAFB_FUSED'];
% rcout.owner          ='flyTEM';
% rcout.project        = 'test';
% rcout.service_host   = '10.37.5.60:8080';
% rcout.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcout.verbose        = 1;
% %%
% overlap = [120 150];
% resp = fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout);




% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
% 
% % configure rough collection
% rcfixed.stack          = ['EXP_FAFB_FUSED'];
% rcfixed.owner          ='flyTEM';
% rcfixed.project        = 'test';
% rcfixed.service_host   = '10.37.5.60:8080';
% rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
% rcfixed.verbose        = 1;
% rcfixed.nfirst         = 1;
% rcfixed.nlast          = 45;
% 
% % configure rough collection
% rcmoving.stack          = ['PROD_FINE_MP1_RR_P1_40_150_xs_2'];
% rcmoving.owner          ='flyTEM';
% rcmoving.project        = 'test2';
% rcmoving.service_host   = '10.37.5.60:8080';
% rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcmoving.verbose        = 1;
% rcmoving.nfirst         = 40;
% rcmoving.nlast          = 150;
% 
% % configure output collection
% rcout.stack          = ['EXP_FAFB_FUSED'];
% rcout.owner          ='flyTEM';
% rcout.project        = 'test';
% rcout.service_host   = '10.37.5.60:8080';
% rcout.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcout.verbose        = 1;
% %%
% overlap = [40 45];
% resp = fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout);




%%


% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
% 
% % configure rough collection
% rcfixed.stack          = ['PROD_FINE_MP1_RR_P1_1_35_xs_2'];
% rcfixed.owner          ='flyTEM';
% rcfixed.project        = 'test2';
% rcfixed.service_host   = '10.37.5.60:8080';
% rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
% rcfixed.verbose        = 1;
% rcfixed.nfirst         = 1;
% rcfixed.nlast          = 35;
% 
% % configure rough collection
% rcmoving.stack          = ['PROD_FINE_MP1_RR_P1_20_45_xs_2'];
% rcmoving.owner          ='flyTEM';
% rcmoving.project        = 'test2';
% rcmoving.service_host   = '10.37.5.60:8080';
% rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcmoving.verbose        = 1;
% rcmoving.nfirst         = 20;
% rcmoving.nlast          = 45;
% 
% % configure output collection
% rcout.stack          = ['EXP_FAFB_FUSED'];
% rcout.owner          ='flyTEM';
% rcout.project        = 'test';
% rcout.service_host   = '10.37.5.60:8080';
% rcout.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcout.verbose        = 1;
% %%
% overlap = [20 35];
% resp = fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout);

% delete_renderer_stack(rcout);