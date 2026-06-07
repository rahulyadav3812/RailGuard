%% ========================================================================
% FILE: run_pipeline.m
% DESCRIPTION: Runs the complete data pipeline in one go.
%              Just click RUN - no typing needed.
%% ========================================================================

clc;
clear;
close all;

fprintf('=============================================================\n');
fprintf('  STARTING COMPLETE DATA PIPELINE\n');
fprintf('=============================================================\n\n');

%% Add all paths
cd('/MATLAB Drive');
addpath(genpath('/MATLAB Drive'));

%% Step 1: Load config
fprintf('STEP 1: Loading configuration...\n');
cfg = config();
fprintf('  Done.\n\n');

%% Step 2: Generate normal data
fprintf('STEP 2: Generating normal data...\n');
normalData = generate_normal_data(cfg);
fprintf('\n');

%% Step 3: Generate attack data
fprintf('STEP 3: Generating attack data...\n');
attackData = generate_attack_data(cfg, normalData);
fprintf('\n');

%% Step 4: Check both tables before combining
fprintf('STEP 4: Checking table compatibility...\n');
fprintf('  Normal data: %d rows x %d cols\n', height(normalData), width(normalData));
fprintf('  Attack data: %d rows x %d cols\n', height(attackData), width(attackData));

fprintf('  Normal columns: ');
disp(normalData.Properties.VariableNames);
fprintf('  Attack columns: ');
disp(attackData.Properties.VariableNames);

% Check for column count match
if width(normalData) ~= width(attackData)
    fprintf('  WARNING: Column count mismatch! Fixing...\n');
    
    % Get common columns
    commonCols = intersect(normalData.Properties.VariableNames, ...
                          attackData.Properties.VariableNames, 'stable');
    normalData = normalData(:, commonCols);
    attackData = attackData(:, commonCols);
    fprintf('  Using %d common columns.\n', length(commonCols));
end

% Force same column order
attackData = attackData(:, normalData.Properties.VariableNames);

% Fix data type mismatches column by column
colNames = normalData.Properties.VariableNames;
for c = 1:length(colNames)
    col = colNames{c};
    nType = class(normalData.(col));
    aType = class(attackData.(col));
    
    if ~strcmp(nType, aType)
        fprintf('  Fixing type: %s (normal=%s, attack=%s)\n', col, nType, aType);
        switch nType
            case 'string'
                attackData.(col) = string(attackData.(col));
            case 'double'
                attackData.(col) = double(attackData.(col));
            case 'cell'
                attackData.(col) = cellstr(string(attackData.(col)));
            case 'datetime'
                attackData.(col) = datetime(attackData.(col));
        end
    end
end
fprintf('  Compatibility check done.\n\n');

%% Step 5: Combine data
fprintf('STEP 5: Combining normal + attack data...\n');
fullData = [normalData; attackData];

% Shuffle
rng(cfg.seed + 200, 'twister');
shuffleIdx = randperm(height(fullData));
fullData = fullData(shuffleIdx, :);

% Re-index
for i = 1:height(fullData)
    fullData.sample_id(i) = sprintf("S%06d", i);
end

nNormal = sum(fullData.label == 0);
nAttack = sum(fullData.label == 1);
fprintf('  Total: %d samples (Normal: %d, Attack: %d)\n', ...
    height(fullData), nNormal, nAttack);
fprintf('  Attack ratio: %.1f%%\n', 100 * nAttack / height(fullData));

% Print attack type distribution
fprintf('  Attack distribution:\n');
attackTypes = unique(fullData.attack_type);
for t = 1:length(attackTypes)
    at = attackTypes(t);
    n = sum(fullData.attack_type == at);
    fprintf('    %-12s: %5d samples\n', at, n);
end
fprintf('\n');

%% Step 6: Extract features
fprintf('STEP 6: Extracting features...\n');
[features, featureNames, labels, attackClass] = feature_extraction(fullData, cfg);
fprintf('\n');

%% Step 7: Normalize
fprintf('STEP 7: Normalizing features...\n');
[normFeatures, normParams] = data_normalization(features, cfg);
fprintf('\n');

%% Step 8: Split train/test
fprintf('STEP 8: Splitting train/test...\n');
[trainData, testData] = data_splitting(normFeatures, labels, attackClass, cfg);
fprintf('\n');

%% Step 9: Save everything
fprintf('STEP 9: Saving data files...\n');

% Create directories if they don't exist
if ~exist('data/raw', 'dir'), mkdir('data/raw'); end
if ~exist('data/processed', 'dir'), mkdir('data/processed'); end
if ~exist('data/train', 'dir'), mkdir('data/train'); end
if ~exist('data/test', 'dir'), mkdir('data/test'); end

save('data/raw/fullData.mat', 'fullData');
save('data/processed/processedData.mat', 'normFeatures', 'labels', 'attackClass', 'normParams', 'featureNames');
save('data/train/trainData.mat', 'trainData');
save('data/test/testData.mat', 'testData');
fprintf('  All data saved.\n\n');

%% SUMMARY
fprintf('=============================================================\n');
fprintf('  DATA PIPELINE COMPLETE\n');
fprintf('=============================================================\n');
fprintf('  Full dataset     : %d samples x %d columns\n', height(fullData), width(fullData));
fprintf('  Features         : %d\n', length(featureNames));
fprintf('  Training samples : %d\n', length(trainData.labels));
fprintf('  Testing samples  : %d\n', length(testData.labels));
fprintf('  Normal samples   : %d\n', nNormal);
fprintf('  Attack samples   : %d\n', nAttack);
fprintf('=============================================================\n');