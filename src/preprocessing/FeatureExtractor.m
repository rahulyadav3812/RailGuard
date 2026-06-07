classdef FeatureExtractor
    properties
        featureNames;
    end
    methods
        function obj = FeatureExtractor()
            obj.featureNames = {};
        end
        function [features, names, labels, attackClass] = extract(obj, fullData, cfg)
            [features, names, labels, attackClass] = feature_extraction(fullData, cfg);
            obj.featureNames = names;
        end
    end
end