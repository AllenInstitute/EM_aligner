function obj = show_pairwise_fail(obj)
%%%%% handle the FAIL type of messages and plot overview figure

%         err_types = {...
%             'PixPair: Low tissue fraction',...
%             'Approx: Peak outside disc', ...
%             'Approx: R value below threshold',...
%             'Deformable triangular mesh failed - No triangles.',...
%             'Region too small',...
%             'Area change too big (max, sum) =',...
%             'Triangles too different'};

if isdeployed, h = figure('Visible', 'off');
% else
% h = figure('Visible', 'on');    
end
if isdeployed, 
    set(gcf, 'Renderer', 'painters');
else
    set(gcf,'Renderer','painters');
    % set(gcf,'Renderer','zbuffer');
    %set(gcf,'Renderer','OpenGL');
end
color_key = {[1 0 1], [0 1 1], [1 0 0], [0 1 0], [0 0 1], [1 1 0], [0.5 0.5 0.5], [0.2 0.2 0.8]};

err_types_disp = {...
    'Low tissue fraction',...
    'Peak outside disc', ...
    'Below threshold',...
    'Deformable triangular mesh failed - No triangles',...
    'Region too small',...
    'Area change too big',...
    'Triangles too different', ...
    'Corr below threshold at start'};

line_width = 1.0;%obj.tiles(1).W/300;
minX = inf;
maxX = -inf;
minY =inf;
maxY = -inf;
%%%%%%%%%%%%%%%% Figure Pairwise: FAIL -- report failure message
%%%%%%%%%%%%%%%%
if isdeployed,
%     [obj h] = show_map(obj, 'all', 'filled', [], [1 1 1;0 0 0]);
    [obj h] = show_map(obj, 'all', 'filled');
else
[obj h] = show_map(obj, 'all', 'filled');
end
% in a new figure show a colorcoded map for pair-wise correlation
% results
obj = update_tile_info(obj);		% we don't need adjacency information in this file
for pix = 1:numel(obj.rprt.alignBK.pair_data)
    % get the tile indices
    t1 = obj.map_id(obj.rprt.alignBK.pair_data(pix).tile1_id);      % get the tile index using the id map
    t2 = obj.map_id(obj.rprt.alignBK.pair_data(pix).tile2_id);      % get the tile index using the id map
    
    
    c = [0 0 1];        % default color is blue
    if obj.rprt.alignBK.pair_data(pix).fail         %% i.e. it failed for some reason
        % assign color accordingly
        try
        % plot a connecting line between this tile pair
        x = [obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)] + obj.tiles(t1).W/2;
        y = [obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)] + obj.tiles(t1).H/2;
        if obj.rprt.alignBK.pair_data(pix).fail==99,
            cc = [0 0 0];
        else
        cc = color_key{obj.rprt.alignBK.pair_data(pix).fail};
        end
        line(x,y,'LineWidth', line_width, 'Color', cc);
               
       if minX>min([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]), minX = min([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]);end
       if maxX<max([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]), maxX = max([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]);end
       if minY>min([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]), minY = min([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]);end
       if maxY<max([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]), maxY = max([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]);end
        
        catch pairfailureERR
            
            disp('----');
            disp(pairfailureERR);
            disp('skipping this pair. Pair:');
            disp(pix);
            disp('----');
        end
    end
end
%%%% construct a legend for the FAIL connection map
% construct as many lines as there are error types, make them
% invisible and use their handles
h_lines = zeros(1,numel(err_types_disp));
for errix = 1:numel(err_types_disp)
    c = color_key{errix};   % color code with the error found
    h_lines(errix) = line([0 0], [0 0],'LineWidth', line_width, 'Color', c);
end
h = legend(h_lines, err_types_disp, 'Location', [0.8 0.8 0.2 0.2], 'FontSize', 16);
caxis([0 1]);
%%% set up the figure so that it can be printed
axis tight;
axis ij;
% view(90,90);

if isdeployed
fac = 10;
xlim([minX-minX/fac maxX+maxX/fac]);
ylim([minY-minY/fac maxY+maxY/fac]);
axis off;
pX = 0;
pY = 0;
set(gcf,'PaperUnits','centimeters');
xSize = 32; ySize = 48;
xLeft = (21-xSize)/2; yTop = (30-ySize)/2;
set(gcf,'PaperPosition',[xLeft yTop xSize ySize]);
set(gcf,'Position',[pX pY xSize*50 ySize*50]);
% set(gcf,'color',[0 0 0]);
% set(gca, 'color', [0 0 0]);
end
title(['   Layer: ' num2str(obj.z) '-- Failed pair correlations   '], 'color', [0 0 0], 'EdgeColor', [1 0 0], 'FontSize', 16);
