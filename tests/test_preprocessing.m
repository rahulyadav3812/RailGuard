function test_preprocessing()
    fprintf('TEST: Preprocessing\n');
    passed = 0; total = 0;
    
    cfg = config();
    
    try
        load('data/raw/fullData.mat', 'fullData');
        
        total=total+1;
        [features, featureNames, labels, attackClass] = feature_extraction(fullData, cfg);
        assert(size(features,2) == 20);
        passed=passed+1; fprintf('  ✓ 20 features extracted\n');
        
        total=total+1;
        assert(length(featureNames) == 20);
        passed=passed+1; fprintf('  ✓ 20 feature names\n');
        
        total=total+1;
        [normFeatures, normParams] = data_normalization(features, cfg);
        colMeans = mean(normFeatures, 1);
        assert(all(abs(colMeans) < 0.5));
        passed=passed+1; fprintf('  ✓ Normalized features near zero mean\n');
        
        total=total+1;
        [trainData, testData] = data_splitting(normFeatures, labels, attackClass, cfg);
        assert(size(trainData.features,1) + size(testData.features,1) == size(normFeatures,1));
        passed=passed+1; fprintf('  ✓ Train+Test = Total samples\n');
        
        total=total+1;
        trainRatio = size(trainData.features,1) / size(normFeatures,1);
        assert(trainRatio > 0.7 && trainRatio < 0.9);
        passed=passed+1; fprintf('  ✓ Train ratio ~70%%: %.1f%%\n', trainRatio*100);
    catch ME
        fprintf('  ✗ FAILED: %s\n', ME.message);
    end
    
    fprintf('  Result: %d/%d passed\n\n', passed, total);
end