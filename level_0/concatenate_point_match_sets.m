function jjout = concatenate_point_match_sets(jj)
%%% given a struct array jj of point-match sets
%%% obtained by parsing json from a REST call
%%% we need to concatenate point-match entries that are possibly duplicate (or more)
%%% i.e. correspond to the same tile pair
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
jjout = [];

if isstruct(jj)
    counter = 1;
    pid = char({jj(:).pId});
    qid = char({jj(:).qId});
    
    pq = [pid qid];
    [D, ia, X] = unique(pq, 'rows');
    % Y = hist(X, unique(X));

    for ix = 1:size(D,1)   % loop over unique set
            %disp([ix counter]); 
            repix = find(X==X(ia(ix)));  % position of occurrences of index ix (ix indexes into pid and qid)
                n = numel(repix);     % number of occurrences of index ix

                
                % make a new jjout entry
                jjout(counter).pGroupId = jj(repix(1)).pGroupId;
                jjout(counter).qGroupId = jj(repix(1)).qGroupId;
                jjout(counter).pId = jj(repix(1)).pId;
                jjout(counter).qId = jj(repix(1)).qId;
                
                jjout(counter).matches.p = jj(repix(1)).matches.p;
                jjout(counter).matches.q = jj(repix(1)).matches.q;
                jjout(counter).matches.w = jj(repix(1)).matches.w;
                
                for pix = 2:n % if there are more repetitions then include those entries into jjout(counter)
                    
                    jjout(counter).matches.p = [jjout(counter).matches.p jj(repix(pix)).matches.p];
                    jjout(counter).matches.q = [jjout(counter).matches.q jj(repix(pix)).matches.q];
                    jjout(counter).matches.w = [jjout(counter).matches.w; jj(repix(pix)).matches.w];
                end
                counter = counter + 1;
    end
else
    warning('concatenate_point_match_sets: check point-match json information');
end
