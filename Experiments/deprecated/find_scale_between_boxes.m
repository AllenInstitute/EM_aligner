%%%% find best scale between two sections
rc.stack          = ['EXP_dmesh_rough_P1_1_35'];
rc.owner          ='flyTEM';
rc.project        = 'test';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;
rc.nfirst         = 1;
rc.nlast          = 35;

z1 = 12;
z2 = 13;

Wbox = [21330 13755 3000 3000];

[fixed, v, url] = get_image_box_renderer(rc, z1, Wbox, 1);
[moving, v, url] = get_image_box_renderer(rc, z2, Wbox, 1);


% [optimizer, metric] = imregconfig('multimodal');
% tform = imregtform(moving,fixed,'similarity',optimizer,metric);
% movingRegistered = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
% imshowpair(fixed, movingRegistered,'Scaling','joint');
% 
% imshow(fixed);figure;imshow(moving);

cpselect(moving, fixed);

t_ = fitgeotrans(fixedPoints,movingPoints,'similarity');