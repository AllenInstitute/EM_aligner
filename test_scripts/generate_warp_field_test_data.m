%%% generate four tile test case for warp-field transformation
rcacquire.stack          = 'v12_acquire_merged';
rcacquire.owner          ='flyTEM';
rcacquire.project        = 'FAFB00';
rcacquire.service_host   = '10.40.3.162:8080';
rcacquire.baseURL        = ['http://' rcacquire.service_host '/render-ws/v1'];
rcacquire.verbose        = 0;

rcmontage.stack          = 'kk14_montage';
rcmontage.owner          ='flyTEM';
rcmontage.project        = 'FAFBv14_kk';
rcmontage.service_host   = '10.40.3.162:8080';
rcmontage.baseURL        = ['http://' rcmontage.service_host '/render-ws/v1'];
rcmontage.verbose        = 0;

rcoutacquire.stack          = 'four_tile_acquire';
rcoutacquire.owner          ='flyTEM';
rcoutacquire.project        = 'test_warp_field';
rcoutacquire.service_host   = '10.40.3.162:8080';
rcoutacquire.baseURL        = ['http://' rcoutacquire.service_host '/render-ws/v1'];
rcoutacquire.verbose        = 0;

rcout.stack          = 'four_tile_montage';
rcout.owner          ='flyTEM';
rcout.project        = 'test_warp_field';
rcout.service_host   = '10.40.3.162:8080';
rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];
rcout.verbose        = 0;

rc_corrupted.stack          = 'four_tile_corrupted';
rc_corrupted.owner          ='flyTEM';
rc_corrupted.project        = 'test_warp_field';
rc_corrupted.service_host   = '10.40.3.162:8080';
rc_corrupted.baseURL        = ['http://' rc_corrupted.service_host '/render-ws/v1'];
rc_corrupted.verbose        = 0;

% generate montage and select tiles
vec = [28 29 33 34];
L = Msection(rcmontage,1);  
tiles = L.tiles(vec);
L = Msection(tiles);
resp = ingest_section_into_renderer_database(L, rcout, rcacquire, '/scratch/khairyk', 1);

% generate acquire and select tiles
vec = [68 69 76 77];
L = Msection(rcacquire,1);  
tiles = L.tiles(vec);
L = Msection(tiles);
resp = ingest_section_into_renderer_database(L, rcoutacquire, rcacquire, '/scratch/khairyk', 1);

%% generate a corrupted affine for each tile
rand('seed', 1000);
L = Msection(rcout,1);  % loads the montage
for ix = 1:numel(L.tiles)
    T = L.tiles(ix).tform.T;
    T([1 2 4 5]) = T([1 2 4 5]) + (rand(1, 4) -0.5) * 0.05;
    T([3 6]) = T([3 6]) + (rand(1,2)-0.5)*10;
    L.tiles(ix).tform.T = T;
    disp(T(1:6)');
end
resp = ingest_section_into_renderer_database(L, rc_corrupted, rcacquire, '/scratch/khairyk', 1);
