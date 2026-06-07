classdef SVMClassifier
    properties
        model; trained;
    end
    methods
        function obj = SVMClassifier()
            obj.model=[]; obj.trained=false;
        end
        function obj = train(obj, XTrain, YTrain, ~)
            obj.model = fitcsvm(XTrain, YTrain, 'KernelFunction','rbf', ...
                'BoxConstraint',1, 'Standardize',true, 'KernelScale','auto');
            obj.model = fitPosterior(obj.model);
            obj.trained = true;
        end
        function [pred, scores] = predict(obj, XTest)
            [pred, scores] = predict(obj.model, XTest);
        end
    end
end