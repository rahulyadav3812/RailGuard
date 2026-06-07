%% ========================================================================
% FILE: feature_extraction.m
% DESCRIPTION: Extracts 20 engineered features from raw data for ML models.
%% ========================================================================

function [features, featureNames, labels, attackClass] = feature_extraction(rawData, cfg)

    fprintf('  [feature_extraction] Extracting features from %d samples...\n', height(rawData));
    timerStart = tic;
    N = height(rawData);

    featureNames = {
        'F01_data_value', 'F02_expected_value', 'F03_value_deviation', ...
        'F04_value_deviation_pct', 'F05_signal_aspect', 'F06_track_occupancy', ...
        'F07_switch_position', 'F08_speed', 'F09_balise_ma', ...
        'F10_network_latency_ms', 'F11_packet_size_bytes', 'F12_comm_interval_ms', ...
        'F13_hash_valid', 'F14_device_id_numeric', 'F15_fog_node_numeric', ...
        'F16_data_type_numeric', 'F17_signal_speed_consistency', ...
        'F18_track_signal_consistency', 'F19_hour_of_day', 'F20_is_peak_hour'
    };

    numFeatures = length(featureNames);
    features = zeros(N, numFeatures);

    % Device ID mapping
    validDevices = string(cfg.edge.devices.id);
    deviceMap = containers.Map();
    for d = 1:length(validDevices)
        deviceMap(char(validDevices(d))) = d;
    end

    % Fog node mapping
    validFogs = string(cfg.fog.nodes.id);
    fogMap = containers.Map();
    for f = 1:length(validFogs)
        fogMap(char(validFogs(f))) = f;
    end

    % Data type mapping
    typeMap = containers.Map( ...
        {'signal','track','point','speed','balise','unknown'}, ...
        {1, 2, 3, 4, 5, 0});

    for i = 1:N
        dv = rawData.data_value(i);
        ev = rawData.expected_value(i);

        features(i, 1) = dv;
        features(i, 2) = ev;
        features(i, 3) = abs(dv - ev);

        if abs(ev) > 0.001
            features(i, 4) = abs(dv - ev) / abs(ev) * 100;
        else
            features(i, 4) = abs(dv - ev) * 100;
        end

        features(i, 5) = rawData.signal_aspect(i);
        features(i, 6) = rawData.track_occupancy(i);
        features(i, 7) = rawData.switch_position(i);
        features(i, 8) = rawData.speed_data(i);
        features(i, 9) = rawData.balise_ma(i);
        features(i, 10) = rawData.network_latency_ms(i);
        features(i, 11) = rawData.packet_size_bytes(i);
        features(i, 12) = rawData.comm_interval_ms(i);

        % Hash validity
        hashIn = sprintf('%s|%s|%.6f|%.6f|%s', ...
            char(rawData.sample_id(i)), char(string(rawData.timestamp(i))), ...
            dv, ev, char(rawData.source_device_id(i)));
        expectedHash = string(hash_generator(hashIn));
        features(i, 13) = double(rawData.integrity_hash(i) == expectedHash);

        % Device ID numeric
        devKey = char(rawData.source_device_id(i));
        if isKey(deviceMap, devKey)
            features(i, 14) = deviceMap(devKey);
        else
            features(i, 14) = 0;
        end

        % Fog node numeric
        fogKey = char(rawData.fog_node_id(i));
        if isKey(fogMap, fogKey)
            features(i, 15) = fogMap(fogKey);
        else
            features(i, 15) = 0;
        end

        % Data type numeric
        dtKey = char(rawData.data_type(i));
        if isKey(typeMap, dtKey)
            features(i, 16) = typeMap(dtKey);
        else
            features(i, 16) = 0;
        end

        % Signal-speed consistency
        sigAspect = rawData.signal_aspect(i);
        spd = rawData.speed_data(i);
        switch sigAspect
            case 1, features(i, 17) = double(spd <= 5);
            case 2, features(i, 17) = double(spd <= 85);
            case 3, features(i, 17) = double(spd <= 205);
            otherwise, features(i, 17) = 0;
        end

        % Track-signal consistency
        if rawData.track_occupancy(i) == 1
            features(i, 18) = double(sigAspect == 1);
        else
            features(i, 18) = 1;
        end

        % Hour of day
        if ~isnat(rawData.timestamp(i))
            features(i, 19) = hour(rawData.timestamp(i));
        else
            features(i, 19) = 12;
        end

        % Peak hour
        h = features(i, 19);
        features(i, 20) = double((h >= 7 && h <= 9) || (h >= 17 && h <= 19));
    end

    labels = rawData.label;
    attackClass = rawData.attack_class;

    features(isnan(features)) = 0;
    features(isinf(features)) = 0;

    elapsed = toc(timerStart);
    fprintf('  [feature_extraction] Done. %d features x %d samples in %.1f s.\n', ...
        numFeatures, N, elapsed);
end