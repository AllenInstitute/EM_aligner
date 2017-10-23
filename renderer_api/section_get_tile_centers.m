function [X, Y, tids] = section_get_tile_centers(rc, z)
% example call: http://tem-services.int.janelia.org:8080/render-ws/v1/owner/flyTEM/project/FAFB00/stack/v12_acquire/z/1/tileBounds

urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tileBounds',...
                 rc.baseURL, rc.owner, rc.project, rc.stack, z);
j = webread(urlChar);
X = zeros(numel(j),1);
Y = zeros(numel(j),1);
tids = cell(numel(j),1);
for ix = 1:numel(j)
    X(ix) = j(ix).maxX-j(ix).minX;
    Y(ix) = j(ix).maxY-j(ix).minY;
    tids{ix} = j(ix).tileId;
end