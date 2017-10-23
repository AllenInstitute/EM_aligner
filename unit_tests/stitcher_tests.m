classdef stitcher_tests < matlab.unittest.TestCase
    
    properties
        rcsource = struct('owner', 'flyTEM', 'project', 'FAFB00', 'stack', 'v12_acquire_merged', ...
            'service_host', '10.37.5.60:8080', 'baseURL', 'http://10.37.5.60:8080/render-ws/v1', ...
            'verbose', 0);
        rctarget = struct('owner', 'flyTEM', 'project', 'test', 'stack', 'Unit_test_stack', ...
            'service_host', '10.37.5.60:8080', 'baseURL', 'http://10.37.5.60:8080/render-ws/v1', ...
            'verbose', 0);
    end
    methods (Test)
        
        function test_solver_AxB_similarity(testCase)
            load('../test_data/solver_data/solver_AxB_similarity_constrained_backslash.mat', 'K', 'Lm', 'options', 'd', 'x2', 'R');
            [xtry, ~] = solve_AxB(K,Lm,options,d);
            act_solution = xtry;
            exp_solution = x2;
            testCase.verifyEqual(act_solution,exp_solution);
        end        
        
        function test_basic_montage(testCase)
            act_solution = basic_montage_local_files();
            exp_solution = 36;
            testCase.verifyEqual(act_solution,exp_solution, 'AbsTol',2);
        end
    end
    
end
