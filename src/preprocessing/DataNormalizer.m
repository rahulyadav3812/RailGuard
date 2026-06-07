classdef DataNormalizer
    properties
        params;
    end
    methods
        function obj = DataNormalizer()
            obj.params = struct();
        end
        function [normData, obj] = normalize(obj, features, cfg)
            [normData, obj.params] = data_normalization(features, cfg);
        end
        function normData = apply(obj, features)
            normData = (features - obj.params.mu) ./ obj.params.sigma;
        end
    end
end