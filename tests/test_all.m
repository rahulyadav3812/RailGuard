%% test_all.m - Run all tests
function test_all()
    clc;
    fprintf('╔═══════════════════════════════════════════════════════════╗\n');
    fprintf('║           RUNNING ALL TESTS                             ║\n');
    fprintf('╚═══════════════════════════════════════════════════════════╝\n\n');
    
    cd('/MATLAB Drive');
    addpath(genpath('/MATLAB Drive'));
    
    totalTimer = tic;
    
    fprintf('═══════════════════════════════════════════\n');
    test_config();
    
    fprintf('═══════════════════════════════════════════\n');
    test_data_generation();
    
    fprintf('═══════════════════════════════════════════\n');
    test_preprocessing();
    
    fprintf('═══════════════════════════════════════════\n');
    test_models();
    
    fprintf('═══════════════════════════════════════════\n');
    fprintf('ALL TESTS COMPLETE. Time: %.1f s\n', toc(totalTimer));
    fprintf('═══════════════════════════════════════════\n');
end