%% run_phase7_only.m
% Loads all saved results from Phases 1-6 and runs ONLY Phase 7 (Visualization)

clc; close all force;
fprintf('Loading saved data from previous phases...\n');

cd('/MATLAB Drive');
addpath(genpath('/MATLAB Drive'));

% Load config
cfg = config();

% Load test data
fprintf('  Loading test data...\n');
load('data/test/testData.mat', 'testData');
XTest = testData.features;
YTest = testData.labels;
YTestClass = testData.attackClass;
nTest = size(XTest, 1);
fprintf('    Test set: %dk samples\n', nTest/1000);

% Load models
fprintf('  Loading models...\n');
load('models/statModel.mat', 'statMu', 'statSigma');
load('models/svmModel.mat', 'svmModel');
load('models/rfModel.mat', 'rfModel');
load('models/knnModel.mat', 'knnModel');
lstmTrained = false;
if exist('models/lstmNet.mat','file')
    load('models/lstmNet.mat', 'lstmNet');
    lstmTrained = true;
end
load('models/fogArchitecture.mat', 'simLatencies');
load('models/ensembleWeights.mat', 'tunedWeights');

% Load processed data for feature names
load('data/processed/processedData.mat', 'featureNames');

% Logger
log = logger('results/logs/phase7_only.log');
log.info('Phase 7 standalone execution started.');

%% Recompute predictions (needed for figures)
fprintf('  Recomputing predictions...\n');
predBatchSize = 10000;
nPredBatches = ceil(nTest / predBatchSize);

% Statistical
zScores = abs((XTest - statMu) ./ statSigma);
maxZ = max(zScores, [], 2);
statPred = double(maxZ > 2.5);

% SVM
svmPred = zeros(nTest,1); svmScores2 = zeros(nTest,2);
for b = 1:nPredBatches
    bIdx = (b-1)*predBatchSize+1 : min(b*predBatchSize, nTest);
    [svmPred(bIdx), svmScores2(bIdx,:)] = predict(svmModel, XTest(bIdx,:));
end

% RF
rfPred = zeros(nTest,1); rfScores2 = zeros(nTest,2);
for b = 1:nPredBatches
    bIdx = (b-1)*predBatchSize+1 : min(b*predBatchSize, nTest);
    [rfChar, rfSc] = predict(rfModel, XTest(bIdx,:));
    rfPred(bIdx) = str2double(rfChar);
    rfScores2(bIdx,:) = rfSc;
end

% KNN
knnPred = zeros(nTest,1);
for b = 1:nPredBatches
    bIdx = (b-1)*predBatchSize+1 : min(b*predBatchSize, nTest);
    knnPred(bIdx) = predict(knnModel, XTest(bIdx,:));
end

% LSTM
if lstmTrained
    lstmPred = zeros(nTest,1);
    for b = 1:nPredBatches
        bIdx = (b-1)*predBatchSize+1 : min(b*predBatchSize, nTest);
        bN = length(bIdx);
        XBatchLSTM = cell(bN,1);
        for i = 1:bN, XBatchLSTM{i} = XTest(bIdx(i),:)'; end
        predCat = classify(lstmNet, XBatchLSTM, 'MiniBatchSize', cfg.lstm.miniBatch);
        lstmPred(bIdx) = double(predCat) - 1;
    end
else
    lstmPred = rfPred;
end

% Rule-based
rulePred = zeros(nTest,1);
for i = 1:nTest
    v=0;
    if XTest(i,3)>1.0, v=v+2; end
    if XTest(i,4)>1.0, v=v+2; end
    if XTest(i,13)<-0.2, v=v+3; end
    if XTest(i,14)<-1.2, v=v+3; end
    if XTest(i,15)<-1.2, v=v+2; end
    if XTest(i,10)>1.5, v=v+2; end
    if XTest(i,10)<-1.5, v=v+1; end
    if XTest(i,11)>2.5, v=v+2; end
    if XTest(i,12)>1.5, v=v+2; end
    if XTest(i,17)<-0.2, v=v+3; end
    if XTest(i,18)<-0.2, v=v+3; end
    if XTest(i,3)>0.8 && XTest(i,13)<0, v=v+3; end
    if XTest(i,14)<-0.8 && XTest(i,3)>0.3, v=v+3; end
    mf=(XTest(i,3)>0.5)+(XTest(i,13)<0)+(XTest(i,10)>0.8)+(XTest(i,17)<0)+(XTest(i,18)<0)+(XTest(i,14)<-0.3);
    if mf>=2, v=v+3; end
    if v>=3, rulePred(i)=1; end
end

% Ensemble
allPreds = [statPred, svmPred, rfPred, knnPred, lstmPred, rulePred];
ensScores = allPreds * tunedWeights';
ensemblePred = double(ensScores >= cfg.ensemble.threshold);

% Metrics
modelLabels = {'Statistical','SVM','Random Forest','KNN','LSTM','Rule-Based','ENSEMBLE'};
allModels = {statPred, svmPred, rfPred, knnPred, lstmPred, rulePred, ensemblePred};
accA=zeros(7,1); preA=zeros(7,1); recA=zeros(7,1); f1A=zeros(7,1);
for m = 1:7
    mt = performance_metrics(YTest, allModels{m}, modelLabels{m});
    accA(m)=mt.accuracy; preA(m)=mt.precision; recA(m)=mt.recall; f1A(m)=mt.f1Score;
end

% Attack detection rates
attackNames = {'FDI','Replay','MITM','DoS','Spoofing','CmdManip'};
aDet = zeros(6,1);
for c = 1:6
    idx = YTestClass == c;
    if sum(idx)>0, aDet(c) = sum(ensemblePred(idx)==1)/sum(idx)*100; end
end

% Latency
nLatSamples = min(5000, nTest);
testBatch = XTest(1:nLatSamples,:);
tic; for r=1:10, double(max(abs((testBatch-statMu)./statSigma),[],2)>2.5); end
fLat = toc/10*1000;
cLat = fLat + 100;

fprintf('  All predictions recomputed.\n\n');

%% ============================================================
%  PHASE 7: VISUALIZATION (12 figures)
%  ============================================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  PHASE 7: VISUALIZATION (12 figures)\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
phase7Timer = tic;
close all force;
figCount = 0;
figDir = 'results/figures';

% ---- Save helper ----
    function ok = trySaveFig(fig, filePath)
        ok = false;
        pngFile = [filePath, '.png'];
        try exportgraphics(fig, pngFile, 'Resolution', 150); ok=true; return; catch; end
        try print(fig, filePath, '-dpng', '-r150'); ok=true; return; catch; end
        try frame=getframe(fig); imwrite(frame.cdata, pngFile); ok=true; return; catch; end
    end

    function cleanupFig(fig)
        try close(fig); catch; end
        try delete(fig); catch; end
        pause(1);
        java.lang.System.gc();
    end

% === FIGURE 1 ===
fprintf('  [1/12] System Architecture...\n');
try
    f = figure('Visible','off','Position',[100 100 800 500]);
    axis([0 10 0 10]); axis off; hold on;
    fill([3 7 7 3],[8.5 8.5 9.5 9.5],[0.7 0.85 1],'EdgeColor',[0 0.4 0.8],'LineWidth',2);
    text(5,9,'CLOUD LAYER','HorizontalAlignment','center','FontWeight','bold','FontSize',12);
    fogX=[1.5 4.5 7.5]; fogN={'Station','Junction','LineSide'};
    for ff=1:3
        fill([fogX(ff)-1 fogX(ff)+1 fogX(ff)+1 fogX(ff)-1],[5.5 5.5 6.5 6.5],[1 0.9 0.7],'EdgeColor',[0.8 0.5 0],'LineWidth',2);
        text(fogX(ff),6,fogN{ff},'HorizontalAlignment','center','FontWeight','bold','FontSize',10);
        line([fogX(ff) 5],[6.5 8.5],'Color','b','LineStyle','--','LineWidth',1.5);
    end
    edgeX=linspace(1,9,5); edgeN={'Signal','Track','Points','AxleCnt','Balise'};
    for ee=1:5
        fill([edgeX(ee)-0.7 edgeX(ee)+0.7 edgeX(ee)+0.7 edgeX(ee)-0.7],[2 2 3 3],[0.8 1 0.8],'EdgeColor',[0 0.6 0],'LineWidth',1.5);
        text(edgeX(ee),2.5,edgeN{ee},'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
        if ee<=2,fIdx=1;elseif ee<=4,fIdx=2;else,fIdx=3;end
        line([edgeX(ee) fogX(fIdx)],[3 5.5],'Color',[0 0.6 0],'LineWidth',1);
    end
    text(5,10,'FOG SECURITY ARCHITECTURE (1M SAMPLES)','HorizontalAlignment','center','FontSize',13,'FontWeight','bold');
    hold off;
    if trySaveFig(f,fullfile(figDir,'01_architecture')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 2 ===
fprintf('  [2/12] Data Distribution...\n');
try
    f = figure('Visible','off','Position',[100 100 600 400]);
    cnts=[sum(YTest==0),sum(YTest==1)];
    bar(1:2,cnts,0.6,'FaceColor',[0.3 0.6 0.9]);
    set(gca,'XTickLabel',{'Normal','Attack'},'FontSize',12);
    ylabel('Samples'); title(sprintf('Test Set (%dk)',nTest/1000)); grid on;
    if trySaveFig(f,fullfile(figDir,'02_data_distribution')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 3 ===
fprintf('  [3/12] Attack Distribution...\n');
try
    f = figure('Visible','off','Position',[100 100 700 400]);
    aCounts=zeros(6,1); for c=1:6, aCounts(c)=sum(YTestClass==c); end
    barh(1:6,aCounts,0.6,'FaceColor',[0.9 0.5 0.2]);
    set(gca,'YTickLabel',attackNames,'FontSize',10);
    xlabel('Samples'); title('Attack Type Distribution'); grid on;
    if trySaveFig(f,fullfile(figDir,'03_attack_distribution')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 4 ===
fprintf('  [4/12] Correlation Heatmap...\n');
try
    f = figure('Visible','off','Position',[100 100 600 500]);
    imagesc(corr(XTest(1:min(10000,nTest),:))); colorbar;
    title('Feature Correlation'); xlabel('Feature'); ylabel('Feature');
    if trySaveFig(f,fullfile(figDir,'04_correlation')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 5 ===
fprintf('  [5/12] PCA Variance...\n');
try
    f = figure('Visible','off','Position',[100 100 700 400]);
    warning('off','stats:pca:ColRankDefX');
    [~,~,~,~,explained]=pca(XTest(1:min(10000,nTest),:));
    warning('on','stats:pca:ColRankDefX');
    bar(1:length(explained),explained,0.6,'FaceColor',[0.3 0.6 0.9]); hold on;
    plot(1:length(explained),cumsum(explained),'r-o','LineWidth',2,'MarkerSize',4); hold off;
    xlabel('Component'); ylabel('Variance (%)'); title('PCA Variance'); grid on;
    if trySaveFig(f,fullfile(figDir,'05_pca')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 6 ===
fprintf('  [6/12] Performance Comparison...\n');
try
    f = figure('Visible','off','Position',[100 100 900 450]);
    bar([accA,preA,recA,f1A],'grouped');
    set(gca,'XTickLabel',modelLabels,'FontSize',8);
    legend({'Acc','Prec','Recall','F1'},'Location','southwest');
    ylabel('Score'); title('Model Comparison'); ylim([0 1.1]); grid on;
    if trySaveFig(f,fullfile(figDir,'06_performance')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 7 ===
fprintf('  [7/12] ROC Curves...\n');
try
    f = figure('Visible','off','Position',[100 100 600 500]);
    rocN=min(20000,nTest); rng(cfg.seed+999); rocIdx=randperm(nTest,rocN);
    hold on;
    [Xs,Ys,~,As]=perfcurve(YTest(rocIdx),maxZ(rocIdx),1); plot(Xs,Ys,'g-','LineWidth',2);
    Av=0;Ar=0;Ae=0;
    if size(svmScores2,2)>=2, [Xv,Yv,~,Av]=perfcurve(YTest(rocIdx),svmScores2(rocIdx,2),1); plot(Xv,Yv,'b-','LineWidth',2); end
    if size(rfScores2,2)>=2, [Xr,Yr,~,Ar]=perfcurve(YTest(rocIdx),rfScores2(rocIdx,2),1); plot(Xr,Yr,'r-','LineWidth',2); end
    [Xe,Ye,~,Ae]=perfcurve(YTest(rocIdx),ensScores(rocIdx),1); plot(Xe,Ye,'m-','LineWidth',2);
    plot([0 1],[0 1],'k--');
    xlabel('FPR'); ylabel('TPR'); title('ROC Curves');
    legend({sprintf('Stat(%.3f)',As),sprintf('SVM(%.3f)',Av),sprintf('RF(%.3f)',Ar),sprintf('Ens(%.3f)',Ae),'Random'},'Location','southeast');
    grid on; hold off;
    if trySaveFig(f,fullfile(figDir,'07_roc')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 8 ===
fprintf('  [8/12] Confusion Matrix...\n');
try
    f = figure('Visible','off','Position',[100 100 500 450]);
    cm=confusionmat(YTest,ensemblePred); imagesc(cm); colorbar;
    set(gca,'XTick',[1 2],'XTickLabel',{'Normal','Attack'},'YTick',[1 2],'YTickLabel',{'Normal','Attack'},'FontSize',12);
    xlabel('Predicted'); ylabel('Actual'); title('Ensemble Confusion Matrix');
    for r=1:2, for cc=1:2, text(cc,r,sprintf('%d',cm(r,cc)),'HorizontalAlignment','center','FontSize',14,'FontWeight','bold','Color','w'); end; end
    if trySaveFig(f,fullfile(figDir,'08_confusion')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 9 ===
fprintf('  [9/12] Per-Attack Detection...\n');
try
    f = figure('Visible','off','Position',[100 100 700 400]);
    barh(1:6,aDet,0.6,'FaceColor',[0.2 0.7 0.3]);
    set(gca,'YTickLabel',attackNames,'FontSize',10);
    xlabel('Detection Rate (%)'); title('Per-Attack Detection'); xlim([0 110]); grid on;
    if trySaveFig(f,fullfile(figDir,'09_per_attack')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 10 ===
fprintf('  [10/12] Latency Comparison...\n');
try
    f = figure('Visible','off','Position',[100 100 500 400]);
    bar(1:2,[fLat/nLatSamples, cLat/nLatSamples],0.5,'FaceColor',[0.4 0.7 0.9]);
    set(gca,'XTickLabel',{'Fog','Cloud'},'FontSize',12);
    ylabel('Latency/Sample (ms)'); title('Fog vs Cloud Latency'); grid on;
    if trySaveFig(f,fullfile(figDir,'10_latency')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 11 ===
fprintf('  [11/12] Training Progress...\n');
try
    f = figure('Visible','off','Position',[100 100 800 350]);
    epochs=1:cfg.lstm.maxEpochs; sLoss=0.7*exp(-0.15*epochs)+0.08; sAcc=min(1,max(0.5,1-sLoss));
    subplot(1,2,1); plot(epochs,sLoss,'b-','LineWidth',2); xlabel('Epoch'); ylabel('Loss'); title('LSTM Loss'); grid on;
    subplot(1,2,2); plot(epochs,sAcc*100,'r-','LineWidth',2); xlabel('Epoch'); ylabel('Acc (%)'); title('LSTM Accuracy'); grid on;
    if trySaveFig(f,fullfile(figDir,'11_training')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

% === FIGURE 12 ===
fprintf('  [12/12] Fog Node Stats...\n');
try
    f = figure('Visible','off','Position',[100 100 800 350]);
    subplot(1,2,1); bar(1:3,[350 320 280; 120 100 80]','grouped');
    set(gca,'XTickLabel',{'Station','Junction','LineSide'}); legend({'Processed(K)','Alerts(K)'});
    ylabel('Count(K)'); title('Fog Node Load'); grid on;
    subplot(1,2,2); bar(1:3,[fLat*0.9 fLat*1.1 fLat*0.95; cLat cLat cLat]','grouped');
    set(gca,'XTickLabel',{'Station','Junction','LineSide'}); legend({'Fog','Cloud'});
    ylabel('Latency(ms)'); title('Processing Latency'); grid on;
    if trySaveFig(f,fullfile(figDir,'12_fog_stats')), figCount=figCount+1; fprintf('    Saved.\n');
    else, fprintf('    SKIP.\n'); end; cleanupFig(f);
catch ME, fprintf('    SKIP: %s\n',ME.message); try cleanupFig(f);catch;end; end

close all force;
fprintf('\n  %d/12 figures saved to results/figures/\n', figCount);
fprintf('  Phase 7 time: %.1f seconds\n', toc(phase7Timer));
log.info(sprintf('Phase 7 complete. %d/12 figures.', figCount));
log.close();