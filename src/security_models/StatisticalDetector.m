classdef StatisticalDetector
    properties
        mu; sigma; threshold; trained;
    end
    methods
        function obj = StatisticalDetector()
            obj.mu=[]; obj.sigma=[]; obj.threshold=2.5; obj.trained=false;
        end
        function obj = train(obj, XTrain, YTrain)
            normalFeats = XTrain(YTrain==0, :);
            obj.mu = mean(normalFeats, 1);
            obj.sigma = std(normalFeats, 0, 1);
            obj.sigma(obj.sigma==0) = 1;
            obj.trained = true;
        end
        function [pred, scores] = predict(obj, XTest)
            scores = max(abs((XTest - obj.mu)./obj.sigma), [], 2);
            pred = double(scores > obj.threshold);
        end
    end
end