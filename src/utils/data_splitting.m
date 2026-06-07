function [trainData, testData] = data_splitting(features, labels, attackClass, cfg)

    fprintf('  [data_splitting] Splitting data (%.0f%% train / %.0f%% test)...\n', ...
        cfg.data.trainRatio * 100, cfg.data.testRatio * 100);

    rng(cfg.seed + 300, 'twister');

    N = size(features, 1);
    trainRatio = cfg.data.trainRatio;
    trainIdx = false(N, 1);
    uniqueClasses = unique(attackClass);

    for c = 1:length(uniqueClasses)
        classIdx = find(attackClass == uniqueClasses(c));
        nClass = length(classIdx);
        nTrain = round(nClass * trainRatio);
        shuffled = classIdx(randperm(nClass));
        trainIdx(shuffled(1:nTrain)) = true;
    end

    testIdx = ~trainIdx;

    trainData.features    = features(trainIdx, :);
    trainData.labels      = labels(trainIdx);
    trainData.attackClass = attackClass(trainIdx);

    testData.features    = features(testIdx, :);
    testData.labels      = labels(testIdx);
    testData.attackClass = attackClass(testIdx);

    fprintf('    Training set: %d samples (Normal: %d, Attack: %d)\n', ...
        sum(trainIdx), sum(labels(trainIdx)==0), sum(labels(trainIdx)==1));
    fprintf('    Testing set : %d samples (Normal: %d, Attack: %d)\n', ...
        sum(testIdx), sum(labels(testIdx)==0), sum(labels(testIdx)==1));

    fprintf('    Class distribution:\n');
    for c = 1:length(uniqueClasses)
        nTr = sum(trainData.attackClass == uniqueClasses(c));
        nTe = sum(testData.attackClass == uniqueClasses(c));
        fprintf('      Class %d: Train=%d, Test=%d\n', uniqueClasses(c), nTr, nTe);
    end
end