%% ========================================================================
% FILE: setup.m
% DESCRIPTION: One-time environment setup. Creates folders, adds paths,
%              checks toolboxes, sets random seed.
%
% HOW TO RUN:
%   1. Open MATLAB
%   2. Navigate to project root: cd('C:\FogSecurityProject')
%   3. Type: setup
%
% AUTHOR: Fog Security Research Team
% DATE: 2024-01-15
%% ========================================================================

function success = setup()

    fprintf('=============================================================\n');
    fprintf('  FOG SECURITY MODEL - ENVIRONMENT SETUP\n');
    fprintf('  Railway Signaling Data Manipulation Detection\n');
    fprintf('=============================================================\n\n');

    success = false;
    projectRoot = pwd;

    %% 1. Check MATLAB version
    fprintf('[1/5] Checking MATLAB version...\n');
    v = ver('MATLAB');
    fprintf('       MATLAB %s %s detected.\n', v.Version, v.Release);

    %% 2. Check toolboxes
    fprintf('[2/5] Checking toolboxes...\n');
    required = {'Statistics and Machine Learning Toolbox', ...
                'Deep Learning Toolbox'};
    allTB = ver;
    allNames = {allTB.Name};
    for i = 1:length(required)
        if any(contains(allNames, required{i}))
            fprintf('       [OK]      %s\n', required{i});
        else
            fprintf('       [MISSING] %s - some features will be limited\n', required{i});
        end
    end

    %% 3. Create directory structure
    fprintf('[3/5] Creating directory structure...\n');
    dirs = {
        'data/raw', 'data/processed', 'data/train', 'data/test', ...
        'src/data_generation', 'src/preprocessing', ...
        'src/fog_architecture', 'src/security_models', ...
        'src/visualization', 'src/utils', ...
        'models', 'results/figures', 'results/tables', 'results/logs', ...
        'tests'
    };
    for i = 1:length(dirs)
        d = fullfile(projectRoot, dirs{i});
        if ~exist(d, 'dir')
            mkdir(d);
            fprintf('       CREATED: %s\n', dirs{i});
        else
            fprintf('       EXISTS:  %s\n', dirs{i});
        end
    end

    %% 4. Add source directories to path
    fprintf('[4/5] Adding paths...\n');
    srcDirs = {'src/utils', 'src/data_generation', 'src/preprocessing', ...
               'src/fog_architecture', 'src/security_models', ...
               'src/visualization', 'tests', 'models'};
    for i = 1:length(srcDirs)
        addpath(fullfile(projectRoot, srcDirs{i}));
    end
    addpath(projectRoot);
    fprintf('       %d directories added to MATLAB path.\n', length(srcDirs)+1);

    %% 5. Set random seed
    fprintf('[5/5] Setting random seed = 42...\n');
    rng(42, 'twister');

    %% Done
    fprintf('\n=============================================================\n');
    fprintf('  SETUP COMPLETE. Project root: %s\n', projectRoot);
    fprintf('  Next step: run main.m\n');
    fprintf('=============================================================\n\n');
    success = true;
end