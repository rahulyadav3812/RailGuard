function test_models()
    fprintf('TEST: Trained Models\n');
    passed = 0; total = 0;
    
    load('data/test/testData.mat', 'testData');
    XTest = testData.features;
    YTest = testData.labels;
    
    % Test each saved model
    models = {'statModel','svmModel','rfModel','knnModel','lstmNet'};
    for m = 1:length(models)
        total = total + 1;
        try
            assert(exist(['models/' models{m} '.mat'], 'file') > 0);
            passed = passed + 1;
            fprintf('  ✓ %s.mat exists\n', models{m});
        catch
            fprintf('  ✗ %s.mat MISSING\n', models{m});
        end
    end
    
    % Test RF predictions
    total = total + 1;
    try
        load('models/rfModel.mat', 'rfModel');
        [predChar, ~] = predict(rfModel, XTest(1:100,:));
        pred = str2double(predChar);
        assert(all(pred==0 | pred==1));
        passed = passed + 1;
        fprintf('  ✓ RF produces valid predictions\n');
    catch ME
        fprintf('  ✗ RF prediction failed: %s\n', ME.message);
    end
    
    % Test SVM predictions
    total = total + 1;
    try
        load('models/svmModel.mat', 'svmModel');
        [pred, scores] = predict(svmModel, XTest(1:100,:));
        assert(size(scores,2) == 2);
        passed = passed + 1;
        fprintf('  ✓ SVM produces valid scores\n');
    catch ME
        fprintf('  ✗ SVM prediction failed: %s\n', ME.message);
    end
    
    % Test ensemble weights
    total = total + 1;
    try
        load('models/ensembleWeights.mat', 'tunedWeights');
        assert(length(tunedWeights) == 6);
        assert(abs(sum(tunedWeights) - 1.0) < 0.01);
        passed = passed + 1;
        fprintf('  ✓ Ensemble weights valid (sum=%.2f)\n', sum(tunedWeights));
    catch ME
        fprintf('  ✗ Ensemble weights failed: %s\n', ME.message);
    end
    
    fprintf('  Result: %d/%d passed\n\n', passed, total);
end