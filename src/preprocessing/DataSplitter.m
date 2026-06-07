classdef DataSplitter
    properties
        trainRatio;
    end
    methods
        function obj = DataSplitter(ratio)
            if nargin<1, ratio=0.7; end
            obj.trainRatio = ratio;
        end
        function [trainData, testData] = split(obj, features, labels, attackClass, cfg)
            [trainData, testData] = data_splitting(features, labels, attackClass, cfg);
        end
    end
end