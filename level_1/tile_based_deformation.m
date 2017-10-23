function [mL, deformation, Ar, S] = tile_based_deformation(mL, lambda)
% assuming affine
%% 
tiles = mL.tiles;
deformation = zeros(numel(tiles),1);
Ar = zeros(numel(tiles),1);
S = zeros(numel(tiles),1);
parfor ix = 1:numel(tiles)
    deformation(ix) = abs(1- det(tiles(ix).tform.T(1:2, 1:2)));

%%%%%%%%
        x = tiles(ix).tform.T(3,1);
        y = tiles(ix).tform.T(3,2);
    Px = [x; x + tiles(ix).W; x + tiles(ix).W; x];
    Py = [y; y; y + tiles(ix).H; y+tiles(ix).H];
    
    %%% transform the points
    P = [Px(:) Py(:) [1 1 1 1]']*tiles(ix).tform.T;

    % check polygon area
    Ar(ix) = polyarea(P(:,1), P(:,2));
    % add polygonperimeter
    s = 0;
    s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
    s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
    s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
    s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
    S(ix) = s;
%%%%%%%%%%%
end

for ix = 1:numel(mL.tiles)
    mL.tiles(ix).confidence = deformation(ix);
end


if nargin>1
    sig = std(S);
    mu = mean(S);
    disp('Mean perimeter:');disp(mu);
    indx = [find(S<(mu-lambda*sig)) find(S>(mu+lambda*sig))];
    for ix = 1:numel(indx)
        disp(['Outlier tile found: ' num2str(indx(ix)) ' .... setting state to -3.']);
        mL.tiles(indx(ix)).state = -3;
    end
end

% %% split into z and display
% ml = split_z(mL);
% figure;
% if nargin>4
% subplot(3,1,1);
% show_map_confidence(ml(j), [1], minconf, maxconf); title('Deformation');
% subplot(3,1,2);
% show_map(ml(j)); title('edge tiles vs. internal tiles');
% 
% subplot(3,1,3);
%  tile_based_point_pair_errors(mL, A, xout, j, [], []);title('Point-match residuals');
% 
% else
% show_map_confidence(ml(j), [1], minconf, maxconf); title('Deformation');
% end


% %%generate histograms
% bin = 2000;
% figure;hist(deformation, bin);title('Deformation');
% figure;hist(Ar, bin);title('Area');
% figure;hist(S, bin);title('Perimeter');


