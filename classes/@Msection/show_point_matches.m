function show_point_matches(obj, flag)

% if flag
% M = obj.pm.M;
% adj = obj.pm.adj;
% using_SURF = 0;
% for pix = 1:size(M,1) % loop over point matches
%     %%%%%transform points for the first of the two tiles
%     if using_SURF,
%         pm = M{pix,1}(:).Location;
%     else   pm = M{pix,1};
%     end
%     T = obj.tiles(adj(pix,1)).tform.T;
%     pmt = pm*T(1:2,1:2);
%     if using_SURF,
%         M{pix,1}(:).Location = pmt;
%     else
%         M{pix,1}(:) = pmt;
%     end
%     %%%%%%%%%%%transform points for the second of the two tiles
%     if using_SURF
%         pm = M{pix,2}(:).Location;
%     else
%         pm = M{pix,2};
%     end
%     T = obj.tiles(adj(pix,2)).tform.T;
%     pmt = pm*T(1:2,1:2);
%     if using_SURF
%         M{pix,2}(:).Location = pmt;
%     else
%         M{pix,2} = pmt;
%     end
% end
% obj.pm.M = M;
% obj.pm.adj = adj;
% end


if numel(obj.tiles)==2
    fac = 0.4;
    maxM = 3;
    m = randi(size(obj.pm.M{1,1},1), maxM,1);
    im1 = imresize(get_image(obj.tiles(1)), fac);
    im2 = imresize(get_image(obj.tiles(2)), fac);
    showMatchedFeatures(im1, im2,obj.pm.M{1,1}(m,:) * fac,obj.pm.M{1,2}(m,:) * fac, 'Method', 'Montage');
    
    
else
    figure;show_map(obj); drawnow;
    hold on;
    fac = 30.0;
    for ix = 1:size(obj.pm.adj,1)
        m1ix = obj.pm.adj(ix,1);
        m2ix = obj.pm.adj(ix,2);
        m1 = obj.pm.M{ix,1};
        m2 = obj.pm.M{ix,2};
        
        
            x1 = obj.tiles(m1ix).tform.T([3]) + obj.tiles(m1ix).W/2;
            y1 = obj.tiles(m1ix).tform.T([6]) + obj.tiles(m1ix).H/2;
        
            x2 = obj.tiles(m2ix).tform.T([3]) + obj.tiles(m2ix).W/2;
            y2 = obj.tiles(m2ix).tform.T([6]) + obj.tiles(m2ix).H/2;

%             w = size(m1,1)/fac;
%             if w>1, w = 1;end
            
            w = 0;
        plot([x1, x2], [y1, y2], 'LineWidth', 2.0, 'Color', [w w w]);hold on;
        
%         % plot lines connecting matching points
%         m1 = [m1 ones(size(m1,1),1)] * obj.tiles(m1ix).tform.T(1:3, 1:3);
%         m2 = [m2 ones(size(m1,1),1)] * obj.tiles(m2ix).tform.T(1:3, 1:3);
%         
%         for pix = 1:size(m1,1)
%             plot([m1(pix,1) m2(pix,1)], [m1(pix,2) m2(pix,2)], 'r-', 'LineWidth', 1.0);
%         end

       % drawnow;
    end
end





















