function [M, adj, W, np, n1] = load_montage_pm(pm, sID, map_id,...
    min_points, max_points, wopts)
% load point-matches from pm for one single section sID
% returns a 1x2 cell of xy coordinate matches M, adjacency (adj) linking the
% two tiles/canvases by index based on their original position determined from map_id
if nargin<6
    wopts = weboptions;
    wopts.Timeout = 60;
end
count = 1;
M = [];
adj = [];
W = [];
np = [];
n1 = [];
% options = weboptions;
% options.Timeout = 20;
n1 = 0;
for six = 1:numel(sID)  % loop over reacquires (if any)
    %disp([six count]);
    jj = get_pms_montage(pm, sID{six}, wopts);
    n1 = n1 + numel(jj);
    for jix = 1:numel(jj)
        if size(jj(jix).matches.p',1)>=min_points
            % make sure both tile ids exist
            if isKey(map_id, jj(jix).pId) && isKey(map_id, jj(jix).qId)
                
                if numel(jj(jix).matches.p(1,:))>max_points
                    indx = randi(numel(jj(jix).matches.p(1,:))-1, max_points,1);
                    M{count,1}   = [jj(jix).matches.p(1:2,indx)]';
                    M{count,2}   = [jj(jix).matches.q(1:2,indx)]';
                    adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                    W{count,1}     = jj(jix).matches.w(indx)';         % relative weights of point matches within this group
                    np(count)    = max_points;
                else
                    M{count,1}   = [jj(jix).matches.p]';
                    M{count,2}   = [jj(jix).matches.q]';
                    adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                    W{count,1}     = jj(jix).matches.w';         % relative weights of point matches within this group
                    np(count)    = size(jj(jix).matches.p',1);
                end
                
                count = count + 1;
            end
        end
    end
    
    
end

%%%% crosslayer for reacquires: get point matches across those individual section ids
for isix = 1:numel(sID)
    for jsix = isix+1:numel(sID)
        jj = get_pms_cross_layer(pm, sID{isix}, sID{jsix}, wopts);
        n1 = n1 + numel(jj);
        for jix = 1:numel(jj)
            if size(jj(jix).matches.p',1)>=min_points
                if isKey(map_id, jj(jix).pId) && isKey(map_id, jj(jix).qId)
                    if numel(jj(jix).matches.p(1,:))>max_points
                        indx = randi(numel(jj(jix).matches.p(1,:))-1, max_points,1);
                        M{count,1}   = [jj(jix).matches.p(1:2,indx)]';
                        M{count,2}   = [jj(jix).matches.q(1:2,indx)]';
                        adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                        W{count,1}     = jj(jix).matches.w(indx)';         % relative weights of point matches within this group
                        np(count)    = max_points;
                    else
                        M{count,1}   = [jj(jix).matches.p]';
                        M{count,2}   = [jj(jix).matches.q]';
                        adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                        W{count,1}     = jj(jix).matches.w';         % relative weights of point matches within this group
                        np(count)    = size(jj(jix).matches.p',1);
                    end
                    
                    count = count + 1;
                end
            end
        end
        
    end
end