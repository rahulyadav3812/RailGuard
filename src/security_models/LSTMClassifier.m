classdef LSTMClassifier
    properties
        net; trained;
    end
    methods
        function obj = LSTMClassifier()
            obj.net=[]; obj.trained=false;
        end
        function obj = train(obj, XTrain, YTrain, cfg)
            numFeat = size(XTrain, 2);
            XCell = cell(size(XTrain,1), 1);
            for i = 1:size(XTrain,1), XCell{i} = XTrain(i,:)'; end
            
            layers = [
                sequenceInputLayer(numFeat)
                lstmLayer(cfg.lstm.units1, 'OutputMode','sequence')
                dropoutLayer(cfg.lstm.dropout)
                lstmLayer(cfg.lstm.units2, 'OutputMode','last')
                dropoutLayer(cfg.lstm.dropout)
                fullyConnectedLayer(2)
                softmaxLayer
                classificationLayer];
            
            opts = trainingOptions('adam', 'MaxEpochs',30, ...
                'MiniBatchSize',cfg.lstm.miniBatch, ...
                'InitialLearnRate',cfg.lstm.learnRate, ...
                'Verbose',false, 'Plots','none');
            
            obj.net = trainNetwork(XCell, categorical(YTrain), layers, opts);
            obj.trained = true;
        end
        function pred = predict(obj, XTest)
            XCell = cell(size(XTest,1), 1);
            for i = 1:size(XTest,1), XCell{i} = XTest(i,:)'; end
            pred = double(classify(obj.net, XCell)) - 1;
        end
    end
end