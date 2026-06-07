%% ========================================================================
% FILE: run_security_models.m
% DESCRIPTION: Trains and evaluates all 6 security models + ensemble
%% ========================================================================

clc;
fprintf('=============================================================\n');
fprintf('  SECURITY MODEL TRAINING & EVALUATION\n');
fprintf('=============================================================\n\n');

cd('/MATLAB Drive');
addpath(genpath('/MATLAB Drive'));

%% Load saved data
fprintf('Loading saved data...\n');
load('data/train/trainData.mat');
load('data/test/testData.mat');
load('data/processed/processedData.mat');
cfg = config();

XTrain = trainData.features;
YTrain = trainData.labels;
YTrainClass = trainData.attackClass;
XTest  = testData.features;
YTest  = testData.labels;
YTestClass = testData.attackClass;

fprintf('  Train: %d samples, Test: %d samples, Features: %d\n\n', ...
    size(XTrain,1), size(XTest,1), size(XTrain,2));

%% ================================================================
%  MODEL 1: STATISTICAL ANOMALY DETECTOR
%  Uses Z-score to flag outliers based on training data statistics
%  ================================================================
fprintf('=== MODEL 1: Statistical Anomaly Detector ===\n');
tic;

% Compute baseline statistics from normal training data
normalIdx = YTrain == 0;
normalFeatures = XTrain(normalIdx, :);
statMu = mean(normalFeatures, 1);
statSigma = std(normalFeatures, 0, 1);
statSigma(statSigma == 0) = 1;

% Compute Z-scores for test data
zScores = abs((XTest - statMu) ./ statSigma);

% A sample is anomalous if ANY feature exceeds threshold
maxZperSample = max(zScores, [], 2);
zThreshold = cfg.statDet.zThreshold;
statPredictions = double(maxZperSample > zThreshold);

statTime = toc;
statMetrics = performance_metrics(YTest, statPredictions, 'Statistical Detector');
fprintf('  Detection time: %.3f seconds\n\n', statTime);

%% ================================================================
%  MODEL 2: SVM CLASSIFIER
%  Support Vector Machine with RBF kernel
%  ================================================================
fprintf('=== MODEL 2: SVM Classifier ===\n');
tic;

% Train SVM (binary: normal vs attack)
svmModel = fitcsvm(XTrain, YTrain, ...
    'KernelFunction', 'rbf', ...
    'BoxConstraint', 1, ...
    'Standardize', true, ...
    'KernelScale', 'auto');

% Enable probability estimates
svmModel = fitPosterior(svmModel);

% Predict
[svmPredictions, svmScores] = predict(svmModel, XTest);

svmTime = toc;
svmMetrics = performance_metrics(YTest, svmPredictions, 'SVM');
fprintf('  Training+prediction time: %.3f seconds\n\n', svmTime);

%% ================================================================
%  MODEL 3: RANDOM FOREST CLASSIFIER
%  Ensemble of decision trees using TreeBagger
%  ================================================================
fprintf('=== MODEL 3: Random Forest Classifier ===\n');
tic;

rfModel = TreeBagger(cfg.ml.rf.numTrees, XTrain, YTrain, ...
    'Method', 'classification', ...
    'MinLeafSize', cfg.ml.rf.minLeafSize, ...
    'OOBPrediction', 'on', ...
    'OOBPredictorImportance', 'on');

% Predict
[rfPredChar, rfScores] = predict(rfModel, XTest);
rfPredictions = str2double(rfPredChar);

rfTime = toc;
rfMetrics = performance_metrics(YTest, rfPredictions, 'Random Forest');
fprintf('  OOB Error: %.4f\n', oobError(rfModel, 'Mode', 'ensemble'));
fprintf('  Training+prediction time: %.3f seconds\n\n', rfTime);

%% ================================================================
%  MODEL 4: KNN CLASSIFIER
%  K-Nearest Neighbors
%  ================================================================
fprintf('=== MODEL 4: KNN Classifier ===\n');
tic;

knnModel = fitcknn(XTrain, YTrain, ...
    'NumNeighbors', cfg.ml.knn.k, ...
    'Distance', cfg.ml.knn.distance, ...
    'Standardize', true, ...
    'DistanceWeight', 'squaredinverse');

[knnPredictions, knnScores] = predict(knnModel, XTest);

knnTime = toc;
knnMetrics = performance_metrics(YTest, knnPredictions, 'KNN');
fprintf('  Training+prediction time: %.3f seconds\n\n', knnTime);

%% ================================================================
%  MODEL 5: LSTM DEEP LEARNING
%  Long Short-Term Memory Network for sequence detection
%  ================================================================
fprintf('=== MODEL 5: LSTM Deep Learning ===\n');
tic;

% Prepare sequences for LSTM
% Each sample becomes a sequence of length 1 with numFeatures dimensions
% Reshape: LSTM expects cell array of [features x timeSteps]
numFeatures = size(XTrain, 2);

XTrainLSTM = cell(size(XTrain, 1), 1);
for i = 1:size(XTrain, 1)
    XTrainLSTM{i} = XTrain(i, :)';  % [features x 1]
end

XTestLSTM = cell(size(XTest, 1), 1);
for i = 1:size(XTest, 1)
    XTestLSTM{i} = XTest(i, :)';
end

YTrainCat = categorical(YTrain);
YTestCat = categorical(YTest);

% Define LSTM architecture
layers = [
    sequenceInputLayer(numFeatures)
    lstmLayer(cfg.lstm.units1, 'OutputMode', 'sequence')
    dropoutLayer(cfg.lstm.dropout)
    lstmLayer(cfg.lstm.units2, 'OutputMode', 'last')
    dropoutLayer(cfg.lstm.dropout)
    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer
];

% Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 30, ...
    'MiniBatchSize', cfg.lstm.miniBatch, ...
    'InitialLearnRate', cfg.lstm.learnRate, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', cfg.lstm.lrDropPeriod, ...
    'LearnRateDropFactor', cfg.lstm.lrDropFactor, ...
    'GradientThreshold', cfg.lstm.gradThreshold, ...
    'Shuffle', 'every-epoch', ...
    'Verbose', true, ...
    'VerboseFrequency', 50, ...
    'Plots', 'none');

% Train LSTM
fprintf('  Training LSTM network...\n');
try
    lstmNet = trainNetwork(XTrainLSTM, YTrainCat, layers, options);
    
    % Predict
    lstmPredCat = classify(lstmNet, XTestLSTM, 'MiniBatchSize', cfg.lstm.miniBatch);
    lstmPredictions = double(lstmPredCat) - 1;  % Convert back to 0/1
    
    lstmTime = toc;
    lstmMetrics = performance_metrics(YTest, lstmPredictions, 'LSTM');
    lstmTrained = true;
catch ME
    fprintf('  LSTM training failed: %s\n', ME.message);
    fprintf('  Using fallback prediction (Random Forest results)...\n');
    lstmPredictions = rfPredictions;
    lstmMetrics = rfMetrics;
    lstmMetrics.modelName = 'LSTM (fallback)';
    lstmTime = toc;
    lstmTrained = false;
end
fprintf('  Training+prediction time: %.3f seconds\n\n', lstmTime);

%% ================================================================
%  MODEL 6: RULE-BASED IDS
%  Railway-specific safety rules
%  ================================================================
fprintf('=== MODEL 6: Rule-Based IDS ===\n');
tic;

load('data/raw/fullData.mat');  % Need original data for rule checks

% Get test indices (last 3000 samples after shuffle)
% Instead, apply rules directly on feature values
rulePredictions = zeros(size(XTest, 1), 1);

for i = 1:size(XTest, 1)
    violations = 0;
    
    % Feature indices from feature_extraction:
    % 1=data_value, 2=expected_value, 3=deviation, 4=deviation_pct
    % 5=signal, 6=track_occ, 7=switch, 8=speed, 9=balise_ma
    % 10=latency, 11=packet_size, 12=comm_interval
    % 13=hash_valid, 14=device_id, 15=fog_node, 16=data_type
    % 17=signal_speed_consist, 18=track_signal_consist
    % 19=hour, 20=peak_hour
    
    % NOTE: Features are normalized, so we use normalized thresholds
    % or compare relative values
    
    devNorm      = XTest(i, 3);   % value deviation (normalized)
    devPctNorm   = XTest(i, 4);   % deviation percent (normalized)
    hashValid    = XTest(i, 13);  % hash validity (normalized)
    deviceID     = XTest(i, 14);  % device ID (normalized)
    fogNode      = XTest(i, 15);  % fog node (normalized)
    latencyNorm  = XTest(i, 10);  % latency (normalized)
    pktSizeNorm  = XTest(i, 11);  % packet size (normalized)
    commIntNorm  = XTest(i, 12);  % comm interval (normalized)
    sigSpdCon    = XTest(i, 17);  % signal-speed consistency (normalized)
    trkSigCon    = XTest(i, 18);  % track-signal consistency (normalized)
    dataTypeNorm = XTest(i, 16);  % data type (normalized)
    
    % Rule 1: Large deviation between data and expected value
    if devNorm > 1.5
        violations = violations + 2;
    end
    
    % Rule 2: Large percentage deviation
    if devPctNorm > 1.5
        violations = violations + 2;
    end
    
    % Rule 3: Hash invalid (below average = likely invalid)
    if hashValid < -0.3
        violations = violations + 3;
    end
    
    % Rule 4: Unknown device (below normal range)
    if deviceID < -1.5
        violations = violations + 3;
    end
    
    % Rule 5: Unknown fog node
    if fogNode < -1.5
        violations = violations + 2;
    end
    
    % Rule 6: Abnormally high latency
    if latencyNorm > 2.0
        violations = violations + 2;
    end
    
    % Rule 7: Abnormally low latency (spoofing indicator)
    if latencyNorm < -1.8
        violations = violations + 1;
    end
    
    % Rule 8: Abnormal packet size (too large)
    if pktSizeNorm > 3.0
        violations = violations + 2;
    end
    
    % Rule 9: Abnormal packet size (too small)
    if pktSizeNorm < -2.0
        violations = violations + 1;
    end
    
    % Rule 10: Abnormal communication interval (too fast)
    if commIntNorm < -0.5
        violations = violations + 1;
    end
    
    % Rule 11: Abnormal communication interval (too slow)
    if commIntNorm > 2.0
        violations = violations + 2;
    end
    
    % Rule 12: Signal-speed inconsistency
    if sigSpdCon < -0.3
        violations = violations + 3;
    end
    
    % Rule 13: Track-signal inconsistency
    if trkSigCon < -0.3
        violations = violations + 3;
    end
    
    % Rule 14: Unknown data type
    if dataTypeNorm < -2.0
        violations = violations + 2;
    end
    
    % Rule 15: Combined deviation + hash invalid
    if devNorm > 1.0 && hashValid < 0
        violations = violations + 3;
    end
    
    % Rule 16: Combined latency + deviation
    if latencyNorm > 1.5 && devNorm > 1.0
        violations = violations + 2;
    end
    
    % Rule 17: Combined unknown device + large deviation
    if deviceID < -1.0 && devNorm > 0.5
        violations = violations + 3;
    end
    
    % Rule 18: Combined packet anomaly + hash invalid
    if (pktSizeNorm > 2.0 || pktSizeNorm < -1.5) && hashValid < 0
        violations = violations + 2;
    end
    
    % Rule 19: Extreme comm interval + any deviation
    if commIntNorm > 3.0
        violations = violations + 2;
    end
    
    % Rule 20: Multiple mild anomalies compound
    mildFlags = (devNorm > 0.8) + (hashValid < 0) + (latencyNorm > 1.0) + ...
                (sigSpdCon < 0) + (trkSigCon < 0) + (deviceID < -0.5);
    if mildFlags >= 3
        violations = violations + 3;
    end
    
    % Decision: attack if violations exceed threshold
    if violations >= 4
        rulePredictions(i) = 1;
    end
end

ruleTime = toc;
ruleMetrics = performance_metrics(YTest, rulePredictions, 'Rule-Based IDS');
fprintf('  Detection time: %.3f seconds\n\n', ruleTime);

%% ================================================================
%  ENSEMBLE MODEL
%  Weighted voting of all 6 models
%  ================================================================
fprintf('=== ENSEMBLE MODEL: Weighted Voting ===\n');
tic;

% Compute weights based on individual F1 scores
f1Scores = [statMetrics.f1Score, svmMetrics.f1Score, rfMetrics.f1Score, ...
            knnMetrics.f1Score, lstmMetrics.f1Score, ruleMetrics.f1Score];
weights = f1Scores / sum(f1Scores);

fprintf('  Model weights (based on F1):\n');
modelNames = {'Statistical', 'SVM', 'RandomForest', 'KNN', 'LSTM', 'RuleBased'};
for m = 1:6
    fprintf('    %-15s: %.4f (F1=%.4f)\n', modelNames{m}, weights(m), f1Scores(m));
end

% Weighted vote
allPredictions = [statPredictions, svmPredictions, rfPredictions, ...
                  knnPredictions, lstmPredictions, rulePredictions];

ensembleScores = allPredictions * weights';
ensemblePredictions = double(ensembleScores >= 0.5);

ensembleTime = toc;
ensembleMetrics = performance_metrics(YTest, ensemblePredictions, 'Ensemble');
fprintf('  Ensemble time: %.3f seconds\n\n', ensembleTime);

%% ================================================================
%  CROSS-VALIDATION (5-fold for best models)
%  ================================================================
fprintf('=== CROSS-VALIDATION (5-fold) ===\n');

cvModel = crossval(svmModel, 'KFold', cfg.ml.cvFolds);
cvLoss = kfoldLoss(cvModel);
fprintf('  SVM 5-fold CV Error: %.4f (Accuracy: %.1f%%)\n', cvLoss, (1-cvLoss)*100);

cvKNN = crossval(knnModel, 'KFold', cfg.ml.cvFolds);
cvLossKNN = kfoldLoss(cvKNN);
fprintf('  KNN 5-fold CV Error: %.4f (Accuracy: %.1f%%)\n\n', cvLossKNN, (1-cvLossKNN)*100);

%% ================================================================
%  SAVE MODELS
%  ================================================================
fprintf('Saving trained models...\n');
if ~exist('models', 'dir'), mkdir('models'); end

save('models/statModel.mat', 'statMu', 'statSigma', 'zThreshold');
save('models/svmModel.mat', 'svmModel');
save('models/rfModel.mat', 'rfModel');
save('models/knnModel.mat', 'knnModel');
if lstmTrained
    save('models/lstmNet.mat', 'lstmNet');
end
save('models/ensembleWeights.mat', 'weights');

%% ================================================================
%  RESULTS COMPARISON TABLE
%  ================================================================
fprintf('\n=============================================================\n');
fprintf('  FINAL RESULTS COMPARISON\n');
fprintf('=============================================================\n');
fprintf('  %-15s | Acc    | Prec   | Recall | F1     | FPR    | FNR    | Time(s)\n', 'Model');
fprintf('  %s\n', repmat('-', 1, 90));

allMetrics = {statMetrics, svmMetrics, rfMetrics, knnMetrics, lstmMetrics, ruleMetrics, ensembleMetrics};
allTimes = [statTime, svmTime, rfTime, knnTime, lstmTime, ruleTime, ensembleTime];

for m = 1:length(allMetrics)
    mt = allMetrics{m};
    fprintf('  %-15s | %.4f | %.4f | %.4f | %.4f | %.4f | %.4f | %.3f\n', ...
        mt.modelName, mt.accuracy, mt.precision, mt.recall, ...
        mt.f1Score, mt.FPR, mt.FNR, allTimes(m));
end

fprintf('=============================================================\n');

% Check against targets
fprintf('\n  TARGET CHECK:\n');
fprintf('  Accuracy >= 95%%:  Ensemble = %.1f%% %s\n', ...
    ensembleMetrics.accuracy*100, iff(ensembleMetrics.accuracy>=0.95, 'PASS', 'NEEDS TUNING'));
fprintf('  Precision >= 93%%: Ensemble = %.1f%% %s\n', ...
    ensembleMetrics.precision*100, iff(ensembleMetrics.precision>=0.93, 'PASS', 'NEEDS TUNING'));
fprintf('  Recall >= 94%%:    Ensemble = %.1f%% %s\n', ...
    ensembleMetrics.recall*100, iff(ensembleMetrics.recall>=0.94, 'PASS', 'NEEDS TUNING'));
fprintf('  F1 >= 93%%:        Ensemble = %.1f%% %s\n', ...
    ensembleMetrics.f1Score*100, iff(ensembleMetrics.f1Score>=0.93, 'PASS', 'NEEDS TUNING'));
fprintf('  FPR <= 5%%:        Ensemble = %.1f%% %s\n', ...
    ensembleMetrics.FPR*100, iff(ensembleMetrics.FPR<=0.05, 'PASS', 'NEEDS TUNING'));
fprintf('  FNR <= 3%%:        Ensemble = %.1f%% %s\n', ...
    ensembleMetrics.FNR*100, iff(ensembleMetrics.FNR<=0.03, 'PASS', 'NEEDS TUNING'));

fprintf('\n=============================================================\n');
fprintf('  ALL MODELS TRAINED AND EVALUATED SUCCESSFULLY\n');
fprintf('=============================================================\n');

%% Helper function
function result = iff(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end