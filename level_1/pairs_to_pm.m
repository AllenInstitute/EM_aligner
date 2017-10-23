function [L, orphans] = pairs_to_pm(L, options, pairs)
% Main purpose: Concatenates point-match information listed in "pairs".
% How it works:
% For one Msection object L, returns a new Msection object containing either all or a subset
% of tiles existing in the input L. In effect stripping the input from tiles whose id does
% not exist in the pairs variable. This has the consequence that orphan tiles will be deleted. They
% are therefore provided as output separately.
% The output L containts a pm field with concatenated point-match information ready for consumption
% by the matrix solver.
% All tile ids need to be unique. 
% Example usage -- used in interpreting montage scapes as Msection object:
% generate Msection object with one tile/layer. each tile is a montage scape
%
% tiles = tile;
% parfor tix = 1:numel(IDS{1})
%     t = tile;
%     t.z = tix;
%     t.id = IDS{1}(tix);
%     t.path = IDS{2}{tix};
%     t.rot = 0;
%     t.fetch_local = 1;
%     tiles(tix) = t;
% end
% L = Msection(tiles);
% % generate point-matches--- pairs variable
% delta = 0;
% pairs = [ones(numel(MATCHES{1}),1) MATCHES{1}(:) MATCHES{2}(:)+delta MATCHES{3}(:)+delta ones(numel(MATCHES{1}),1) MATCHES{4}(:) MATCHES{5}(:)+delta MATCHES{6}(:)+delta];
% options.verbose = 0;
% options.minpmblock = 0;
% options.minpmblock_cross = 0;
% [L, orphans] = pairs_to_pm(L, options, pairs)
%
% Author: Khaled Khairy. Janelia Research Campus. Copyright 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
orphans = [];
z = L.z;

plindx = (double(pairs(:,1)==z) + double(pairs(:,5)==z))==2;% logical index for all entries in pairs specific to this layer
if isempty(plindx), error('No tiles in "pairs" correspond to tiles in L');end
p = pairs(plindx,:);    % reduce "pairs" to entries specific to this layer z
unqt = unique([p(:,2);p(:,6)]); % get the unique tile ids within this group
tvec = [L.tiles(:).id];
%if numel(unqt)<numel(tvec)
if (sum(ismember(tvec, unqt)) ~= numel(tvec))
    disp('Some tile ids are not present in "pairs"');
    missing_set = setdiff(tvec, unqt);
    disp('specific ids:');
    disp(num2str(missing_set(:)));
    disp('indices in L (output as orphan tiles):');
    orphans = intersect(missing_set, tvec);
    %disp(orphans(:));
    disp(['Total missing tiles: ' num2str(numel(missing_set))]);
elseif numel(unqt)>numel(tvec)
    disp('Some tile ids are present in "pairs" but missing in Msection: This should not happen.');
else
    % disp('All tiles ids accounted for in both point-match files and Msection object');
end

%%% generate new tiles array from intersection of both
[C, ia, ib] = intersect(tvec, unqt);
tiles = L.tiles(ia);
if ~isempty(tiles)
    L = Msection(tiles);
    %%%
    [M, adj] = layerwise_matches(L, z, pairs, options); % concatenate point-matches (slow)
    L.pm.M = M;
    L.pm.adj = adj;
else
    error('Cannot have empty layer');
end


%% add a weights vector to pm struct to account for distance across sections
W = ones(size(L.pm.adj,1),1);
n = zeros(size(L.pm.adj,1),1);  % number of point matches
for ix = 1:length(W)
    z1 = L.tiles(L.pm.adj(ix,1)).z;
    z2 = L.tiles(L.pm.adj(ix,2)).z;
    W(ix) = 1/(1 + abs(z1-z2));
    n(ix) = numel(L.pm.M{ix,1});
end
L.pm.W = W;
L.pm.n = n;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [M, adj] = layerwise_matches(L, z,pairs, options)
% Returns block matches and adjacency for this layer using "pairs"
plindx = (double(pairs(:,1)==z) + double(pairs(:,5)==z))==2;     % logical index for all entries in pairs specific to this layer
pairs = pairs(plindx,:);        % reduce "pairs" to the entries specific to this layer z

% now we only need to worry about tiles within this layer z
unqt = unique([pairs(:,2);pairs(:,6)]);
nunqt = numel(unqt);
M = {};
adj = [];
counter = 1;
minpmblock = options.minpmblock;
minpmblock_deleted = 0;
for tix = 1:nunqt
    % process tile tix in column pairs(:,2)
    
    % check if this tile id is present in L
    if isKey(L.map_id,unqt(tix))
        tix1 = L.map_id(unqt(tix));    % we will need this linear index for adj later on
        
        lindx = pairs(:,2)==unqt(tix);  % logical index correspondign to tile in pairs(:,2)
        pblock= pairs(lindx,:); % occurrences of tile unqt(tix) in pairs(:,2)
        if ~isempty(pblock)
            pairs(lindx,:) = [];    % remove this pblock from pairs  --- SOSI ---VERY EXPENSIVE STEP
            % from this pblock we need to extract subblocks
            unqm = unique(pblock(:,6));
            nunqm = numel(unqm);
            for tmix = 1:nunqm      % loop over the potential partners
                %%% make sure the tile id exists in L
                if isKey(L.map_id,unqm(tmix))
                    tix2 = L.map_id(unqm(tmix)); % needed for adj later on
                    %%% now it is safe to add new data to M and adj
                    mlindx = pblock(:,6)==unqm(tmix);
                    pmblock = pblock(mlindx,:);     % this is the subblock
                    if size(pmblock,1) > minpmblock
                        % generate an M entry for subblocks of each extracted block
                        M{counter,1} = pmblock(:,[3 4]); % store coordinates of one side
                        M{counter,2} =  pmblock(:,[7 8]); % store coordinates of the other
                        % generate an adj entry corresponding to the M subblocks above
                        adj = [adj; tix1 tix2];
                        counter = counter + 1;
                    else
                        minpmblock_deleted  = minpmblock_deleted + 1;
                    end
                else
                    %                     disp('Key not present -- 2');
                end
            end
        end
    else
        %         disp('Key not present -- 1');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% now do the same but using pairs(:,6)

for tix = 1:nunqt
    % process tile tix in column pairs(:,2)
    
    % check if this tile id is present in L
    if isKey(L.map_id,unqt(tix))
        tix1 = L.map_id(unqt(tix));    % we will need this linear index for adj later on
        
        lindx = pairs(:,6)==unqt(tix);  % logical index correspondign to tile in pairs(:,2)
        pblock= pairs(lindx,:); % occurrences of tile unqt(tix) in pairs(:,2)
        if ~isempty(pblock)
            pairs(lindx,:) = [];    % remove this pblock from pairs
            % from this pblock we need to extract subblocks
            unqm = unique(pblock(:,2));
            nunqm = numel(unqm);
            for tmix = 1:nunqm      % loop over the potential partners
                %%% make sure the tile id exists in L
                if isKey(L.map_id,unqm(tmix))
                    tix2 = L.map_id(unqm(tmix)); % needed for adj later on
                    %%% now it is safe to add new data to M and adj
                    mlindx = pblock(:,2)==unqm(tmix);
                    pmblock = pblock(mlindx,:);     % this is the subblock
                    if size(pmblock,1) > minpmblock
                        % generate an M entry for subblocks of each extracted block
                        M{counter,1} = pmblock(:,[3 4]); % store coordinates of one side
                        M{counter,2} =  pmblock(:,[7 8]); % store coordinates of the other
                        % generate an adj entry corresponding to the M subblocks above
                        adj = [adj; tix1 tix2];
                        counter = counter + 1;
                    else
                        minpmblock_deleted  = minpmblock_deleted + 1;
                    end
                else
                    %                     disp('Key not present -- 2');
                end
            end
        end
    else
        %         disp('Key not present -- 1');
    end
end




















