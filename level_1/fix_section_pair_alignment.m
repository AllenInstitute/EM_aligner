function fix_section_pair_alignment(rc, rc_base, z1,z2, scale)
% manually fix alignment mismatch between a pair of sections using
% montage-scapes

[Wbox1, bbox, url] = get_section_bounds_renderer(rc, z1);
im1 = get_image_box_renderer(rc, z1, Wbox1, scale);
[Wbox2, bbox, url] = get_section_bounds_renderer(rc, z2(1));
im2 = get_image_box_renderer(rc, z2(1), Wbox2, scale);
%    figure, imshowpair(im1,im2,'blend')
%% fix pairs manually
p1 = [];
p2 = [];

%[p1, p2] = cpselect(im1,im2, 'Wait', true);
load p;
if ~isempty(p1)&&~isempty(p2)
    t_ = fitgeotrans(p2, p1, 'affine');
    R = imref2d(size(im1));
    im2r = imwarp(im2,t_,'OutputView',R);
    figure, imshowpair(im1,im2r,'blend')
    pause(2);
    close;
    %%% calculate transformation relative to current box
    L_m = Msection;
    L_m(1) = Msection(rc,z1);
    L_m(2) = Msection(rc,z2(1));
    mL = concatenate_tiles(L_m, 1e3);
    
    mL3 = get_bounding_box(mL);
    Wbox = [mL3.box(1) mL3.box(3) mL3.box(2)-mL3.box(1) mL3.box(4)-mL3.box(3)];disp(Wbox);
    wb1 = Wbox(1);
    wb2 = Wbox(2);
    L3 = L_m;
    fac = scale;
    smx = [fac 0 0; 0 fac 0; 0 0 1]; %scale matrix
    invsmx = [1/fac 0 0; 0 1/fac 0; 0 0 1];
    tmx2 = [1 0 0; 0 1 0; -wb1 -wb2 1]; % translation matrix for montage_scape stack
    
    
    %% apply to all tiles in z2
        dx = Wbox2(1) + t_.T(3);
        dy = Wbox2(2) + t_.T(6);
        tmx1 = [1 0 0; 0 1 0; dx dy 1];  % translation matrix for section box
        t_.T([3 6]) = -t_.T([3 6]) * 1/scale;
        for tix = 1:numel(L_m(2).tiles)
            Told = L3(2).tiles(tix).tform.T;
            newT = Told * t_.T;
            % newT = Told * tmx1 * smx * t_.T * tmx2 * (invsmx);
            %newT = L3(lix).tiles(tix).tform.T * tmx1 * invsmx * mL3s(lix).tiles(1).tform.T * tmx1 * (smx);
            L_m(2).tiles(tix).tform.T = newT;
        end
        [append_resp] = ingest_section_into_LOADING_collection...
            (L_m(2),rc, rc_base, pwd, 0);
    disp('Completing stack');
    resp = set_renderer_stack_state_complete(rc);
    disp('Done with ingestion');
end
%%
figure;
show_map(L_m(1));
hold on;
show_map(L_m(2));
