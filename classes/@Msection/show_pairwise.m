function obj = show_pairwise(obj,option)

if option==1, disp('Showing STAT: ImproveControlPts: Initial affine correlation');end
if option==2, disp('Showing STAT: ImproveControlPts: Final affine correlation');end
if option==3, disp('Showing STAT: ImproveControlPts: Initial deformable mesh correlation');end
if option==4, disp('Showing STAT: ImproveControlPts: Final deformable mesh correlation');end
if option==5, disp('Showing Approx: LowRes  R');end
if option==6, disp('Showing Approx: FullRes  R');end
if option==7, disp('Showing Approx: err');end

if isdeployed, h = figure('Visible', 'off');
    % else
    % h = figure('Visible', 'on');
end


if isdeployed,
    %set(gcf, 'Renderer', 'OpenGL');
    set(gcf, 'Renderer', 'painters');
else
    set(gcf,'Renderer','painters');
    %set(gcf,'Renderer','zbuffer');
end
[obj] = show_map(obj, 'all', '');
line_width = obj.tiles(1).W/300;

for pix = 1:numel(obj.rprt.alignBK.pair_data)
    c(pix) = 0;
    if isempty(obj.rprt.alignBK.pair_data(pix).fail_message)
        if ~isempty(obj.rprt.alignBK.pair_data(pix).corr_initial_affine)
            if option ==1
                if ~isnan(obj.rprt.alignBK.pair_data(pix).corr_initial_affine)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).corr_initial_affine;   %
                end
            elseif option==2
                if ~isnan(obj.rprt.alignBK.pair_data(pix).corr_final_affine)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).corr_final_affine;   %
                end
            elseif option==3
                if ~isnan(obj.rprt.alignBK.pair_data(pix).corr_initial_deform)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).corr_initial_deform;   %
                end
            elseif option==4
                if ~isnan(obj.rprt.alignBK.pair_data(pix).corr_final_deform)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).corr_final_deform;   %
                end
            elseif option==5
                if ~isempty(obj.rprt.alignBK.pair_data(pix).approxLowRes)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).approxLowRes;   %
                end
            elseif option==6
                if ~isempty(obj.rprt.alignBK.pair_data(pix).approxFullRes)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).approxFullRes;   %
                end
            elseif option==7
                if ~isempty(obj.rprt.alignBK.pair_data(pix).approxerr)
                    c(pix) = obj.rprt.alignBK.pair_data(pix).approxerr;   %
                end
            end
        end
        
    end
end
colormap gray;
c = mat2gray(c);
minX = inf;
maxX = -inf;
minY =inf;
maxY = -inf;

for pix = 1:numel(obj.rprt.alignBK.pair_data)
    % get the tile indices
    %f(pix) = (obj.rprt.alignBK.pair_data(pix).fail);
    %if isempty(obj.rprt.alignBK.pair_data(pix).fail)          % we will only plot for non-failed pairs
        t1 = obj.map_id(obj.rprt.alignBK.pair_data(pix).tile1_id);      % get the tile index using the id map
        t2 = obj.map_id(obj.rprt.alignBK.pair_data(pix).tile2_id);      % get the tile index using the id map
        w = obj.tiles(t1).W/2;
        h = obj.tiles(t1).H/2;
        if obj.tiles(t1).state==1 && obj.tiles(t2).state==1
        try
        %         % plot a connecting line between this tile pair
        x = [obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)] + w ;
        y = [obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)] + h;
        line(x,y,'LineWidth', line_width, 'Color', [c(pix) c(pix) c(pix)]);
        
        fac = 4;
        X = [x(1)+w/fac x(2)+w/fac x(2)-w/fac x(1)-w/fac]';
        Y = [y(1)+h/fac y(2)+h/fac y(2)-h/fac y(1)-h/fac]';
        patch(X,Y,c(pix), 'Visible', 'off');
        
        if minX>min([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]), minX = min([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]);end
        if maxX<max([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]), maxX = max([obj.tiles(t1).tform.T(3,1) obj.tiles(t2).tform.T(3,1)]);end
        if minY>min([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]), minY = min([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]);end
        if maxY<max([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]), maxY = max([obj.tiles(t1).tform.T(3,2) obj.tiles(t2).tform.T(3,2)]);end
        catch pairwiseERR
            disp('----');
            disp(pairwiseERR);
            disp('skipping this pair. Pair:');
            disp(pix);
            disp('----');
        end
        end
    %end
end
caxis([0 1]);
colorbar
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
    set(gcf,'color',[0 0 0]);
    set(gca, 'color', [0 0 0]);
    set(gcf, 'InvertHardCopy', 'off');
end
if option==1, title(['     Layer: ' num2str(obj.z) '-- STAT: ImproveControlPts: Initial affine correlation     '], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end
if option==2, title(['     Layer: ' num2str(obj.z) '-- STAT: ImproveControlPts: Final affine correlation     '], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end
if option==3, title(['     Layer: ' num2str(obj.z) '-- STAT: ImproveControlPts: Initial deformable mesh correlation     '], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end
if option==4, title(['     Layer: ' num2str(obj.z) '-- STAT: ImproveControlPts: Final deformable mesh correlation      '], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end
if option==5, title(['     Layer: ' num2str(obj.z) '-- Approx: LowRes  correlation coefficient     '], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end
if option==6, title(['     Layer: ' num2str(obj.z) '-- Approx: FullRes correlation coefficient     '], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end
if option==7, title(['     Layer: ' num2str(obj.z) '-- Pairwise relative deviation from disc center'], 'color', [1 1 1], 'EdgeColor', [1 0 0], 'FontSize', 16);end








































