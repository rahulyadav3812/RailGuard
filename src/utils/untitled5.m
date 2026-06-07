cfg = config();
fprintf('Normal samples  : %d\n', cfg.data.numNormalSamples);
fprintf('Attack samples  : %d\n', cfg.data.totalAttackSamples);
fprintf('Total dataset   : %d\n', cfg.data.numNormalSamples + cfg.data.totalAttackSamples);
fprintf('Edge devices    : %d\n', cfg.edge.numDevices);
fprintf('Fog nodes       : %d\n', cfg.fog.numNodes);
fprintf('LSTM classes    : %d\n', cfg.lstm.numClasses);
fprintf('Train/Test split: %.0f%%/%.0f%%\n', cfg.preprocess.trainRatio*100, (1-cfg.preprocess.trainRatio)*100);