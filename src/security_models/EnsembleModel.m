classdef EnsembleModel
    properties
        weights; threshold;
    end
    methods
        function obj = EnsembleModel(weights, threshold)
            if nargin<1, weights=[0.15,0.15,0.35,0.10,0.15,0.10]; end
            if nargin<2, threshold=0.35; end
            obj.weights = weights;
            obj.threshold = threshold;
        end
        function [pred, scores] = predict(obj, allPreds)
            scores = allPreds * obj.weights';
            pred = double(scores >= obj.threshold);
        end
    end
end