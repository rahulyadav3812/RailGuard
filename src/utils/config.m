function cfg = config()
%% ========================================================================
% config.m - Central configuration - Scaled to 500,000 samples
%% ========================================================================

    %% Random Seed
    cfg.seed = 42;

    %% ============================================================
    %  DATA CONFIGURATION - 500,000 SAMPLES
    %  ============================================================
    cfg.data.numNormalSamples   = 350000;
    cfg.data.totalAttackSamples = 150000;
    cfg.data.totalSamples       = 500000;
    cfg.data.trainRatio         = 0.80;
    cfg.data.testRatio          = 0.20;
    cfg.data.timeCoverage_days  = 14;
    cfg.data.samplingRate_Hz    = 1;

    % Attack samples as STRUCT (matching your generate_attack_data.m)
    cfg.data.attackSamples.FDI      = 60000;    % 12%
    cfg.data.attackSamples.replay   = 25000;    % 5%
    cfg.data.attackSamples.MITM     = 20000;    % 4%
    cfg.data.attackSamples.DoS      = 20000;    % 4%
    cfg.data.attackSamples.spoofing = 15000;    % 3%
    cfg.data.attackSamples.cmdManip = 10000;    % 2%

    %% ============================================================
    %  RAILWAY PARAMETERS (used by state machine)
    %  ============================================================
    cfg.rail.maxSpeed_kmh       = 120;
    cfg.rail.speedLimit.green   = 120;
    cfg.rail.speedLimit.yellow  = 40;
    cfg.rail.speedLimit.red     = 0;
    cfg.rail.maxAccel_ms2       = 0.9;
    cfg.rail.maxDecel_ms2       = 1.1;
    cfg.rail.emergDecel_ms2     = 1.5;
    cfg.rail.numTrackSections   = 10;
    cfg.rail.sectionLength_km   = 2.0;

    %% ============================================================
    %  SIGNAL PARAMETERS
    %  ============================================================
    cfg.signal.aspects     = [1, 2, 3];
    cfg.signal.aspectNames = {'Red','Yellow','Green'};
    cfg.signal.aspectProb  = [0.25, 0.30, 0.45];
    cfg.signal.maxSpeed    = [0, 40, 120];

    %% ============================================================
    %  NETWORK PARAMETERS
    %  ============================================================
    cfg.network.latencyMean      = 10;
    cfg.network.latencyStd       = 3;
    cfg.network.latencyMin       = 1;
    cfg.network.latencyMax       = 50;
    cfg.network.packetSizeRange  = [64, 512];
    cfg.network.commIntervalMean = 1000;
    cfg.network.commIntervalStd  = 100;

    %% ============================================================
    %  EDGE DEVICES (5)
    %  ============================================================
    cfg.edge.numDevices = 5;
    cfg.edge.devices.id   = {'ED001','ED002','ED003','ED004','ED005'};
    cfg.edge.devices.name = {'Signal S1','Track Circuit TC1','Point Machine P1','Axle Counter AC1','Balise B1'};
    cfg.edge.devices.type = {'signal','track_circuit','point_machine','axle_counter','balise'};

    %% ============================================================
    %  FOG NODES (3)
    %  ============================================================
    cfg.fog.numNodes = 3;
    cfg.fog.nodes.id      = {'FN001','FN002','FN003'};
    cfg.fog.nodes.type    = {'station','junction','lineside'};
    cfg.fog.nodes.edgeMap = { {'ED001','ED002'}, {'ED003','ED004'}, {'ED005'} };
    cfg.fog.latencyRange_ms    = [1, 20];
    cfg.fog.processingDelay_ms = [2, 15];
    cfg.fog.maxCapacity        = 250000;

    %% ============================================================
    %  CLOUD
    %  ============================================================
    cfg.cloud.syncInterval_s     = 300;
    cfg.cloud.retrainThreshold   = 5000;
    cfg.cloud.storageCapacity_GB = 500;

    %% ============================================================
    %  SECURITY
    %  ============================================================
    cfg.security.encryption    = 'AES-256';
    cfg.security.keyExchange   = 'RSA-2048';
    cfg.security.hashAlgorithm = 'SHA-256';
    cfg.security.tlsEnabled    = true;

    %% ============================================================
    %  ML HYPERPARAMETERS
    %  ============================================================
    cfg.ml.stat.threshold = 2.5;

    cfg.ml.svm.kernelFunction = 'rbf';
    cfg.ml.svm.boxConstraint  = 1;
    cfg.ml.svm.kernelScale    = 'auto';

    cfg.ml.rf.numTrees    = 200;
    cfg.ml.rf.minLeafSize = 10;

    cfg.ml.knn.k        = 7;
    cfg.ml.knn.distance = 'euclidean';

    cfg.lstm.units1        = 128;
    cfg.lstm.units2        = 64;
    cfg.lstm.dropout       = 0.3;
    cfg.lstm.learnRate     = 0.001;
    cfg.lstm.miniBatch     = 512;
    cfg.lstm.maxEpochs     = 20;
    cfg.lstm.lrDropPeriod  = 7;
    cfg.lstm.lrDropFactor  = 0.5;
    cfg.lstm.gradThreshold = 1;

    cfg.ensemble.weights   = [0.15, 0.15, 0.35, 0.10, 0.15, 0.10];
    cfg.ensemble.threshold = 0.35;

    %% ============================================================
    %  TRAINING SUBSAMPLING (memory management)
    %  ============================================================
    cfg.training.maxSamples_svm  = 40000;
    cfg.training.maxSamples_rf   = 80000;
    cfg.training.maxSamples_knn  = 40000;
    cfg.training.maxSamples_lstm = 30000;

    %% ============================================================
    %  FEATURES
    %  ============================================================
    cfg.features.count = 20;

    %% ============================================================
    %  PROCESSING
    %  ============================================================
    cfg.processing.batchSize       = 50000;
    cfg.processing.verboseInterval = 50000;
    cfg.processing.maxMemory_GB    = 16;

end