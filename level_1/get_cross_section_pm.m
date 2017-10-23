function [xPM, np_vec] = get_cross_section_pm(n, pm, sID, map_id, ...
                                      min_points, xs_weight, max_points)
% assumes sectionId contains sections sorted by z
% small xs_weight means less weight for cross-layer point-match
if nargin<6, xs_weight = 1;end
if nargin<7, max_points = inf;end

np_vec = [];
xPM.M = {};
xPM.adj = [];
xPM.W = {};
xPM.np = [];
options = weboptions;
options.Timeout = 20;
sec_ix = 1;
if numel(sID)>=n
    np_vec = zeros(numel(n:numel(sID)),1);
    fac = (1/n * xs_weight);   % small fac ==> less weight for cross-layer point matches
    
    for ix = n:numel(sID)
        np_vec(sec_ix) = 0;
        count = 1;
        for six1 = 1:numel(sID{ix})
            for six2 = 1:numel(sID{ix-(n-1)})
                
                j = get_pms_cross_layer(pm, sID{ix-(n-1)}{six2}, sID{ix}{six1}, options);
                
%                 urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWith/%s', ...
%                     pm.server, pm.owner, pm.match_collection, sID{ix-(n-1)}{six2}, sID{ix}{six1});
%                 %disp(['Cross: ' num2str(ix) ' ' num2str(six1) ' ' num2str(six2) ' ' sID{ix-(n-1)}{six2} ' ' sID{ix}{six1}]);
%                 j = webread(urlChar, options);
                
                %         np_vec(ix-(n-1)) = numel(j);
                for jix = 1:numel(j)
                    if size(j(jix).matches.p',1)>=min_points
                        if isKey(map_id, j(jix).pId) && isKey(map_id, j(jix).qId)
                            
                            % %                             % sosi
                            % %                             if str2double(sID{ix}{six1})==10
                            % %                                 disp([map_id(j(jix).pId)<map_id(j(jix).qId) ...
                            % %                                      n (ix-(n-1)) ix map_id(j(jix).pId) map_id(j(jix).qId)]);
                            % %                             end
                            
                            % obtain map ids
                            midp = map_id(j(jix).pId);
                            midq = map_id(j(jix).qId);
                            
                            if numel(j(jix).matches.p(1,:))>max_points
                                indx = randi(numel(j(jix).matches.p(1,:))-1, max_points,1);
                                if midp<midq
                                    xPM(ix-(n-1)).M{count,1}   = j(jix).matches.p(1:2,indx)';
                                    xPM(ix-(n-1)).M{count,2}   = j(jix).matches.q(1:2,indx)';
                                    xPM(ix-(n-1)).adj(count,:) = [midp midq];
                                else
                                    xPM(ix-(n-1)).M{count,1}   = j(jix).matches.q(1:2,indx)';
                                    xPM(ix-(n-1)).M{count,2}   = j(jix).matches.p(1:2, indx)';
                                    xPM(ix-(n-1)).adj(count,:) = [midq midp];
                                end
                                xPM(ix-(n-1)).W{count,1}   = fac * j(jix).matches.w(indx)';         % relative weights of point matches within this group
                                xPM(ix-(n-1)).np(count)  = max_points;    %  we are recording the number of point matches between those two tiles
                                
                            else
                                if midp<midq
                                    xPM(ix-(n-1)).M{count,1}   = j(jix).matches.p';
                                    xPM(ix-(n-1)).M{count,2}   = j(jix).matches.q';
                                    xPM(ix-(n-1)).adj(count,:) = [midp midq];
                                else
                                    xPM(ix-(n-1)).M{count,1}   = j(jix).matches.q';
                                    xPM(ix-(n-1)).M{count,2}   = j(jix).matches.p';
                                    xPM(ix-(n-1)).adj(count,:) = [midq midp];
                                end
                                xPM(ix-(n-1)).W{count,1}   = fac * j(jix).matches.w';         % relative weights of point matches within this group
                                xPM(ix-(n-1)).np(count)  = size(j(jix).matches.p',1);    %  we are recording the number of point matches between those two tiles
                                
                                
                            end
                            
                            count = count + 1;
                            np_vec(sec_ix) = np_vec(sec_ix) +  1;
                            
                        end
                    end
                end
                %pause(0.2);
            end
        end
        sec_ix = sec_ix + 1;
    end
end
