%% ========================================================================
% FILE: data_normalization.m
%% ========================================================================

function [normFeatures, params] = data_normalization(features, cfg, existingParams)

    fprintf('  [data_normalization] Normalizing features...\n');

    if nargin < 3
        params.mu = mean(features, 1, 'omitnan');
        params.sigma = std(features, 0, 1, 'omitnan');
        params.sigma(params.sigma == 0) = 1;
    else
        params = existingParams;
    end

    normFeatures = (features - params.mu) ./ params.sigma;
    normFeatures(isnan(normFeatures)) = 0;
    normFeatures(isinf(normFeatures)) = 0;

    fprintf('    Feature range after normalization: [%.2f, %.2f]\n', ...
        min(normFeatures(:)), max(normFeatures(:)));
end