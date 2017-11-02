function [xout, yout, err] = local_to_world(rc, tileId, x, y)
% coordinate mapping of a point from local coordiantes xyz to rc
if iscell(tileId), tileId = tileId{1};end
if strcmp(class(x), 'double'), x = num2str(x(:));y = num2str(y(:));end
err = 0;
xout = zeros(size(x,1),1);
yout = zeros(size(y,1),1);


for ix = 1:size(x,1)
    % map from tile local to rc world and return new coordinate
    url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/local-to-world-coordinates/%s,%s',...
        rc.baseURL, rc.owner, rc.project, rc.stack, tileId, x(ix,:), y(ix,:));
    
    U = matlab.net.URI(url);
    try
        jj2 = webread(char(U));
        
        xout(ix) = jj2.world(1);
        yout(ix) = jj2.world(2);
    catch err_read_point
        xout = [];
        yout = [];
        err = 1;
    end
end