function [obj, A, S, delvec] = detect_spurious_tiles(obj)
% use with caution: under construction
%
%
% show map of all tiles within the layer
% Usage: obj = show_map(obj, option, style, font_size)
%           option (default: 'all')  'all', 'registered only', 'marked for removal'
%           style (default: 'filled')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fac = 1.7;
A = [];
S = [];
trans = [];
obj = update_tile_info(obj);		% we don't need adjacency information in this file

%%% determine polygonal areas
for ix = 1:numel(obj.tiles)
    if strcmp(class(obj.tiles(ix).tform), 'affine2d')
        x = obj.tiles(ix).tform.T(3,1);
        y = obj.tiles(ix).tform.T(3,2);
    else
        x = 0;
        y = 0;
    end
    Px = [x; x + obj.tiles(ix).W/obj.map_display_fac; x + obj.tiles(ix).W/obj.map_display_fac; x];
    Py = [y; y; y + obj.tiles(ix).H/obj.map_display_fac; y+obj.tiles(ix).H/obj.map_display_fac];
    
    %%% transform the points
    if strcmp(class(obj.tiles(ix).tform), 'affine2d')
        P = [Px(:) Py(:) [1 1 1 1]']*obj.tiles(ix).tform.T;
    else
        P = transformPointsInverse(obj.tiles(ix).tform,[Px Py]);
    end
    % check polygon area
    A(ix) = polyarea(P(:,1), P(:,2));
    % add polygonperimeter
    s = 0;
    s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
    s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
    s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
    s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
    S(ix) = s;
    % translation
    trans(ix,:) =[x y]; 
end

%%% determine outliers based on area
% check polygon area
% stat = regstats(A,1:numel(A), 'linear', 'cookd');
% %%%% remove from dataset
% thresh = areathresh;
% indx = stat.cookd>thresh;
indx = logical(abs(A/median(A))>fac | abs(A/median(A))<1/fac);
%disp([num2str(sum(indx)) ' tiles are outliers --- by area threshold']);

% disp(['Median: ' num2str(median(A))]);
% disp(num2str([find(indx) A(find(indx))]));
inda = indx;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%% determine perimeter outliers 
% stat = regstats(S,1:numel(S), 'linear', 'cookd');
% %%%% remove from data
% thresh = perimthresh;
% indx = stat.cookd>thresh;
indx = logical(abs(S/median(S))>fac| abs(S/median(S))<1/fac);
%disp([num2str(sum(indx)) ' tiles outliers ---- perimeter threshold']);

% disp(find(indx));
% disp(['Median: ' num2str(median(S))]);
% disp(num2str([find(indx) S(find(indx))]));
indp = indx;



delvec = find([inda + indp]);




% %%% determine x translation outliers 
% stat = regstats(trans(:,1),1:numel(trans(:,1)), 'linear', 'cookd');
% %%%% remove from data
% thresh = transthresh;
% indx = stat.cookd>thresh;
% disp([num2str(sum(indx)) ' tiles outliers by x translation threshold']);
% disp(find(indx));
% disp(num2str([find(indx) trans(find(indx),1)]));
% 
% %%% determine y translation outliers 
% trans(indx,:) = [];
% stat = regstats(trans(:,2),1:numel(trans(:,2)), 'linear', 'cookd');
% %%%% remove from data
% thresh = transthresh;
% indx = stat.cookd>thresh;
% disp([num2str(sum(indx)) ' tiles outliers by y translation threshold']);
% disp(find(indx));
% disp(num2str([find(indx) trans(find(indx),2)]));
