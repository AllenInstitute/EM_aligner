    url1 = 'http://10.37.5.60:8080/render-ws/v1/owner/flyTEM/project/test/stack/EXP_v12_rough_1_4/z/4/box/792,5669,4068,4402,0.25/render-parameters?filter=true';
    url2 = 'http://10.37.5.60:8080/render-ws/v1/owner/flyTEM/project/test/stack/EXP_v12_rough_1_4/z/3/box/792,5669,4068,4402,0.25/render-parameters?filter=true';
    urls{bix} = {url1, url2};
    [m_2, m_1, ~, err_logs{bix}] = point_match_gen_SIFT_qsub(url2, url1, SIFTopts);   % submits jobs -- returns point-matches in box coordinate system%%% production --- submit to cluster
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%% sosi test best siftopts
    SIFTopts.SIFTfdSize        = 8;
    SIFTopts.SIFTmaxScale      = 0.82;
    SIFTopts.SIFTminScale      = 0.3;
    SIFTopts.SIFTsteps         = 5;
    
    SIFTopts.matchMaxEpsilon     = 50;
    SIFTopts.matchRod            = 0.99;
    SIFTopts.matchMinNumInliers  = 10;
    SIFTopts.matchMinInlierRatio = 0.5;
	clear sift_opts
    counter = 1;
    M_1 = {};
    M_2 = {};
    for fd_size = 10 : -2.0: 4
        for max_scale = 0.6 : 0.1: 0.9 
            for min_scale = 0.4 :0.1: 0.5
                for steps = 4 : 2 : 8
                    for match_max_epsilon = 15:5:25
                        for match_rod = 0.85 : 0.05 : 0.97
                            for match_min_numinliers = 10:5:20
                                for match_min_inlier_ratio = 0.0
                                    
                                    
                                    SIFTopts.SIFTfdSize        = fd_size;
                                    SIFTopts.SIFTmaxScale      = max_scale;
                                    SIFTopts.SIFTminScale      = min_scale;
                                    SIFTopts.SIFTsteps         = steps;
                                    
                                    SIFTopts.matchMaxEpsilon     = match_max_epsilon;
                                    SIFTopts.matchRod            = match_rod;
                                    SIFTopts.matchMinNumInliers  = match_min_numinliers;
                                    SIFTopts.matchMinInlierRatio = match_min_inlier_ratio;
                                    
                                    sift_opts(counter) = SIFTopts;
                                    counter = counter + 1;
                                    m_1 = [];
                                    m_2 = [];
                                    disp('-------------------------------');
                                    disp(SIFTopts);
                                     disp(counter);
                                    disp('-------------------------------');
                                    try
                                    [m_2, m_1, ~, err_logs{bix}] = point_match_gen_SIFT_qsub(url2, url1, SIFTopts);   % submits jobs -- returns point-matches in box coordinate system%%% production --- submit to cluster
                                    catch
                                        disp('Skipping');
                                    end
                                    M_1{counter} = m_1;
                                    M_2{counter} = m_2;
                                    disp('Result:');
                                    disp(size(m_1));
                                end
                            end
                        end
                    end
                end
            end
        end
    end
