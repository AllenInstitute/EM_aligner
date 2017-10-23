function [L, tIds, PM, pm_mx, sectionIds, zvals, pm_strength]  = check_pm_data(nfirst, nlast, rc, pm, opts)
%%%% check point-match data in a collection visually
% example usage:
%%% check dmesh point-match collection for FAFBv12
% clc;kk_clock;
% nfirst = 100;
% nlast  = 105;
%
%
% % configure rough collection
% rc.stack          = 'v12_align';
% rc.owner          ='flyTEM';
% rc.project        = 'FAFB00';
% rc.service_host   = '10.37.5.60:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
%
% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'v12_dmesh';
%
% % % configure rough collection
% % rc.stack          = ['EXP_v12_rough_' num2str(nfirst) '_' num2str(nlast)];
% % rc.owner          ='flyTEM';
% % rc.project        = 'test';
% % rc.service_host   = '10.37.5.60:8080';
% % rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% % rc.verbose        = 1;
% %
% % % configure point-match collection
% % pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% % pm.owner            = 'flyTEM';
% % pm.match_collection = 'FAFBv12Test17';
%
%
% opts.min_points = 10;
% opts.nbrs = 3;
%
% Author: Khaled Khairy. Janelia Research Campus
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[L, tIds, PM, pm_mx, sectionIds, zvals] = load_point_matches(nfirst, nlast, rc, pm, opts.nbrs);

if numel(unique([L.tiles(:).z]))==1, 
    show_point_matches(L);
else


%T = array2table(pm_mx);disp(T);


% % 
% % look at pm_mx (matrix that shows number of point-match groups
% % (i.e. one occurrence is between a pair of tiles or canvases). pm_mx shows this
% % within tiles of the same section and across sections
if size(pm_mx,1)>1
    L_vec = split_z(L);
    figure(1);
    surf(pm_mx);axis ij; axis tight;view(2);colorbar;colormap(gray);
    caxis([min(pm_mx(pm_mx>0)) max(pm_mx(:))]);
    title('Number of match groups within/between sections');
    drawnow;
    
    
    % weight pm_mx using the number of tiles in a section to get an idea of
    % relative strengh of connections
    
    format shortG
    pm_strength = zeros(size(pm_mx));
    for ix = 1:size(pm_mx,1)
        for jx = ix:ix + 4 %size(pm_mx,2)
            if jx<=size(pm_strength,2)
                %         z1 = nfirst + ix - 1;
                %         z2 = nfirst + jx - 1;
                %         ntiles = sum([L.tiles(:).z]==z1) + sum([L.tiles(:).z]==z2);
                pm_strength(ix,jx) = pm_mx(ix,jx)/(numel(L_vec(ix).tiles) + numel(L_vec(jx).tiles));
                %         disp([z1 z2 ntiles pm_strength(ix,jx)]);
            end
        end
    end
    % look at pm_strength (matrix that shows relative strength of point-match
    % connections. It weighs pm_mx against total number of tiles
    figure(2);
    surf(pm_strength);axis ij; axis tight;view(2);colorbar;colormap(gray);
    caxis([min(pm_strength(pm_strength>0)) max(pm_strength(:))]);
    title('strength of matching within/between sections');
    drawnow;
    
    
    % title-tile connection strength for one section
    
    
    
    
    
    if ~(isfield(opts, 'plot_cartoons')) || opts.plot_cartoons
        %%% plot cartoons with tile midpoints based on provided collection
        L = update_tile_sources(L, rc);
        % associate each tile with a coordinate
        for tix = 1:numel(L.tiles)
            z(tix) = L.tiles(tix).z;
            j = get_tile_spec_renderer(L.tiles(tix));
            str = j.tileSpecs.transforms.specList(end).dataString;
            c = strsplit(str);
            x(tix) = str2double(c{5});
            y(tix) = str2double(c{6});
        end
        
        % loop over edges of L.G to plot edges
        figure(5);
        ax = gca;
        for eix = 1:size(L.G.Edges,1)
            edg = table2cell(L.G.Edges(eix,1));
            rid1 = edg{1}{1};
            rid2 = edg{1}{2};
            indx1 = L.map_renderer_id(rid1);
            indx2 = L.map_renderer_id(rid2);
            
            X = [x(indx1) x(indx2)];
            Y = [y(indx1) y(indx2)];
            Z = [z(indx1) z(indx2)];
            if Z(1)==Z(2)
                line(X,Y,Z,'LineWidth',1, 'Color',[.5 .5 .5],'Parent',ax);hold on;
            else
                line(X,Y,Z,'LineWidth',1, 'Color',[.2 .2 .2],'Parent',ax);hold on;
            end
            plot3(X,Y,Z, '*b');
        end
        
        % loop over sections and generate rectangles
        for six = 1:numel(sectionIds)
            [Wbox, bbox, url] = get_section_bounds_renderer(rc, zvals(six));
            X = [bbox(1) bbox(3) bbox(3) bbox(1)];
            Y = [bbox(2) bbox(2) bbox(4) bbox(4)];
            Z = [zvals(six) zvals(six) zvals(six) zvals(six)];
            figure(5);hold on; patch(X, Y, Z, 'red', 'FaceAlpha', 0.2, 'EdgeColor', 'k', 'LineWidth', 1.0);
        end
        
        daspect('auto');
        view(3);cameramenu;
    end
end



% figure(3);
% tt_str = centrality(L.G, 'degree');figure;hist(tt_str);
% 
% p = plot(L.G,'Layout','force','EdgeAlpha',0.005,'NodeColor','r');
% deg_ranks = centrality(L.G,'degree','Importance',L.G.Edges.Weight);
% edges = linspace(min(deg_ranks),max(deg_ranks),7);
% bins = discretize(deg_ranks,edges);
% p.MarkerSize = bins;


end























