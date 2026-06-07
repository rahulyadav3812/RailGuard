function metrics = performance_metrics(trueLabels, predLabels, modelName)

    if nargin < 3, modelName = 'Model'; end

    TP = sum(trueLabels == 1 & predLabels == 1);
    TN = sum(trueLabels == 0 & predLabels == 0);
    FP = sum(trueLabels == 0 & predLabels == 1);
    FN = sum(trueLabels == 1 & predLabels == 0);

    metrics.modelName   = modelName;
    metrics.TP = TP;
    metrics.TN = TN;
    metrics.FP = FP;
    metrics.FN = FN;
    metrics.accuracy    = (TP + TN) / (TP + TN + FP + FN);
    metrics.precision   = TP / max(TP + FP, 1);
    metrics.recall      = TP / max(TP + FN, 1);
    metrics.f1Score     = 2 * (metrics.precision * metrics.recall) / max(metrics.precision + metrics.recall, 1e-10);
    metrics.FPR         = FP / max(FP + TN, 1);
    metrics.FNR         = FN / max(FN + TP, 1);
    metrics.specificity = TN / max(TN + FP, 1);
    metrics.confusionMat = [TN FP; FN TP];

    fprintf('    Accuracy: %.1f%%, Precision: %.4f, Recall: %.4f, F1: %.4f\n', ...
        metrics.accuracy*100, metrics.precision, metrics.recall, metrics.f1Score);
end