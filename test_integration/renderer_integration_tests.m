classdef renderer_integration_tests < matlab.unittest.TestCase
    
    properties
        rcsource = struct('owner', 'flyTEM', 'project', 'FAFB00', 'stack', 'v12_acquire_merged', ...
            'service_host', '10.37.5.60:8080', 'baseURL', 'http://10.37.5.60:8080/render-ws/v1', ...
            'verbose', 0);
        rctarget = struct('owner', 'flyTEM', 'project', 'test', 'stack', 'System_integration_test_stack', ...
            'service_host', '10.37.5.60:8080', 'baseURL', 'http://10.37.5.60:8080/render-ws/v1', ...
            'verbose', 0);
    end
    methods (Test)
        
        %%%% before testing any stitching-related methods that require
        %%%% renderer access, we need to test renderer functions work
        function test_stack_exists(testCase)
            act_solution = stack_exists(testCase.rcsource);
            exp_solution = 1;
            testCase.verifyEqual(act_solution,exp_solution);
        end
        
        function test_stack_complete(testCase)
            act_solution = stack_complete(testCase.rcsource);
            exp_solution = 1;
            testCase.verifyEqual(act_solution, exp_solution);
        end
        
        function test_renderer_create_stack(testCase)
            act_solution = create_renderer_stack(testCase.rctarget);
            exp_solution = 0;
            testCase.verifyEqual(act_solution, exp_solution);
        end
        
        function test_stack_loading_false(testCase)
            act_solution = stack_loading(testCase.rcsource);
            exp_solution = 0;
            testCase.verifyEqual(act_solution, exp_solution);
        end 
        function test_stack_loading_true(testCase)
            act_solution = stack_loading(testCase.rctarget);
            exp_solution = 1;
            testCase.verifyEqual(act_solution, exp_solution);
        end 
        
        function test_renderer_service_access(testCase)
            act_solution = renderer_service_tests(testCase.rcsource, testCase.rctarget);
            exp_solution = 4;
            testCase.verifyEqual(act_solution,exp_solution);
        end
        
        function test_basic_montage_using_renderer_collection(testCase)
            section_z = 4.0; % this is the section z-coordinate value to be montaged
            act_solution = basic_montage_renderer_collection(testCase.rcsource, testCase.rctarget, section_z);
            exp_solution = 36;
            testCase.verifyEqual(act_solution,exp_solution, 'AbsTol', 2);
            
        end
       

    end
    
end
