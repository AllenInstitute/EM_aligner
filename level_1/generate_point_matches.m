function generate_point_matches(nfirst, nlast, fnjson)
% --- needs interface to spark script as an option
% fn is json configuration for point-match generation
% for example: fnjson = '/groups/flyTEM/home/khairyk/EM_aligner/matlab_compiled/sample_point_match_gen_pairs_input.json';

% read json input
sl = loadjson(fileread(fnjson));

rcrough = sl.target_collection;

% use spark script
% ----  not implemented yet----

% OR:
% use Matlab's SURF
% obtain rough-aligned tiles
%rcrough.stack = 'Test_llm_04_prll_rough';
warning('Using matlab surf: this could take a long time for large sections');
[Lrough, tiles_rough] = get_slab_tiles(rcrough, nfirst, nlast);
Lrough.dthresh_factor = 1.3;
Lrough = update_adjacency(Lrough);
%aa = Lrough.A;nnz(aa);spy(aa);

% update tile information
for tix = 1:numel(Lrough.tiles)
    Lrough.tiles(tix).stack = rcrough.stack;
    Lrough.tiles(tix).owner = rcrough.owner;
    Lrough.tiles(tix).project = rcrough.project;
    Lrough.tiles(tix).server = rcrough.baseURL;
end

% determine tile pairs and generate point-matches

[r, c] = ind2sub(size(Lrough.A), find(Lrough.A));  % neighbors are determined by the adjacency matrix
mt = Lrough.tiles;

%% generate list of potential tile pairs
% chunck it up into pieces
tp = {};
tile_pairs = tile;
chnk = 1000;
tpcount = 1;
count = 1;
for pix = 1: numel(r)
    %disp(['Point matching: ' num2str(pix) ' of ' num2str(numel(r))]);
        % check whether the pair is a cross-section pair and within limits 
        % of nbrs

        if abs(mt(r(pix)).z-mt(c(pix)).z)>0 &&...
                abs(mt(r(pix)).z-mt(c(pix)).z)<nbrs+1
%         disp(['Matching tile ' num2str(r(pix)) ' zval: ' num2str(mt(r(pix)).z) ...
%            ' with tile ' num2str(c(pix)) ' zval: ' num2str(mt(c(pix)).z)]);
            tile_pairs(count,1) = mt(r(pix));
            tile_pairs(count,2) = mt(c(pix));
            count = count + 1;
        end
        
        if count>=chnk || pix==numel(r)
            count = 1;
            tp{tpcount} = tile_pairs;
            tile_pairs = tile;
            tpcount = tpcount + 1;
        end
end
%% 


for tpix = 1:numel(tp)
    disp(['**** processing tile set: ' num2str(tpix) ' of ' num2str(numel(tp))]);
    tic
    tset = tp{tpix};
    point_match_gen(sl, tset);
    toc
end