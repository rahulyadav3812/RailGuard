classdef KNNClassifier
    properties
        model; trained;
    end
    methods
        function obj = KNNClassifier()
            obj.model=[]; obj.trained=false;
        end
        function obj = train(obj, XTrain, YTrain, cfg)
            obj.model = fitcknn(XTrain, YTrain, 'NumNeighbors',cfg.ml.knn.k, ...
                'Distance',cfg.ml.knn.distance, 'Standardize',true, ...
                'DistanceWeight','squaredinverse');
            obj.trained = true;
        end
        function [pred, scores] = predict(obj, XTest)
            [pred, scores] = predict(obj.model, XTest);
        end
    end
end