classdef RFClassifier
    properties
        model; trained;
    end
    methods
        function obj = RFClassifier()
            obj.model=[]; obj.trained=false;
        end
        function obj = train(obj, XTrain, YTrain, cfg)
            obj.model = TreeBagger(cfg.ml.rf.numTrees, XTrain, YTrain, ...
                'Method','classification', 'MinLeafSize',cfg.ml.rf.minLeafSize, ...
                'OOBPrediction','on', 'OOBPredictorImportance','on');
            obj.trained = true;
        end
        function [pred, scores] = predict(obj, XTest)
            [predChar, scores] = predict(obj.model, XTest);
            pred = str2double(predChar);
        end
        function imp = featureImportance(obj)
            imp = obj.model.OOBPermutedPredictorDeltaError;
        end
    end
end