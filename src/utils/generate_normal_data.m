%% ========================================================================
% FILE: generate_normal_data.m
% DESCRIPTION: Generates 700,000 synthetic normal railway signaling samples
%              Preserves full state machine, interlocking logic, peak patterns
%              Optimized for 1M scale with batch hash generation
%% ========================================================================

function data = generate_normal_data(cfg)

    fprintf('  [generate_normal_data] Starting generation of %d normal samples...\n', ...
        cfg.data.numNormalSamples);
    timerStart = tic;

    rng(cfg.seed, 'twister');
    N = cfg.data.numNormalSamples;

    %% ================================================================
    %  PRE-ALLOCATE ALL COLUMNS
    %  ================================================================
    fprintf('    Pre-allocating arrays for %dk samples...\n', N/1000);
    sample_id           = strings(N, 1);
    timestamp           = NaT(N, 1);
    source_device_id    = strings(N, 1);
    fog_node_id         = strings(N, 1);
    data_type           = strings(N, 1);
    data_value          = zeros(N, 1);
    expected_value      = zeros(N, 1);
    integrity_hash      = strings(N, 1);
    network_latency_ms  = zeros(N, 1);
    packet_size_bytes   = zeros(N, 1);
    protocol_type       = strings(N, 1);
    signal_aspect       = zeros(N, 1);
    track_occupancy     = zeros(N, 1);
    switch_position     = zeros(N, 1);
    speed_data          = zeros(N, 1);
    balise_ma           = zeros(N, 1);
    comm_interval_ms    = zeros(N, 1);
    label               = zeros(N, 1);
    attack_type         = strings(N, 1);
    attack_class        = zeros(N, 1);

    %% ================================================================
    %  BUILD EDGE-TO-FOG MAPPING
    %  ================================================================
    deviceIDs   = cfg.edge.devices.id;
    deviceTypes = cfg.edge.devices.type;
    numDev      = cfg.edge.numDevices;

    edgeToFog = containers.Map();
    for f = 1:cfg.fog.numNodes
        assignedEdges = cfg.fog.nodes.edgeMap{f};
        for e = 1:length(assignedEdges)
            edgeToFog(assignedEdges{e}) = cfg.fog.nodes.id{f};
        end
    end

    %% ================================================================
    %  GENERATE REALISTIC TIMESTAMPS
    %  ================================================================
    fprintf('    Creating time distribution with peak/off-peak patterns...\n');
    timestamps = generate_time_distribution_local(N, datetime(2024, 1, 15, 0, 0, 0));

    %% ================================================================
    %  PRE-COMPUTE FOG MAPPINGS (avoid repeated Map lookups)
    %  ================================================================
    fprintf('    Pre-computing device-to-fog mappings...\n');
    fogMapping = strings(numDev, 1);
    for d = 1:numDev
        if isKey(edgeToFog, deviceIDs{d})
            fogMapping(d) = string(edgeToFog(deviceIDs{d}));
        else
            fogMapping(d) = "FN001";
        end
    end

    %% ================================================================
    %  PRE-GENERATE RANDOM NUMBERS IN BULK (much faster than per-sample)
    %  ================================================================
    fprintf('    Pre-generating random numbers...\n');
    randSwitch     = rand(N, 1);
    randSpeedNoise = randn(N, 1) * 0.3;
    randMA_yellow  = rand(N, 1);
    randMA_green   = rand(N, 1);
    randLatency    = rand(N, 1);
    randPacketExtra = randi(448, N, 1);

    %% ================================================================
    %  SIMULATE FULL RAILWAY STATE MACHINE
    %  ================================================================
    fprintf('    Simulating railway state machine for %dk samples...\n', N/1000);

    sig_state   = 3;
    trk_state   = 0;
    sw_state    = 0;
    cur_speed   = 0;
    train_pos   = 0;

    trainCycleLength = round(N / 50);
    cycleCounter = 0;

    % Progress tracking
    progressInterval = max(1, floor(N / 20));
    lastProgressTime = tic;

    %% ================================================================
    %  MAIN GENERATION LOOP
    %  ================================================================
    for i = 1:N

        %% --- Select Edge Device (round-robin) ---
        devIdx  = mod(i - 1, numDev) + 1;
        devID   = deviceIDs{devIdx};
        devType = deviceTypes{devIdx};

        %% --- Fill identifiers ---
        sample_id(i)        = sprintf("N%07d", i);
        timestamp(i)        = timestamps(i);
        source_device_id(i) = string(devID);
        fog_node_id(i)      = fogMapping(devIdx);
        protocol_type(i)    = "MQTT";
        attack_type(i)      = "none";
        label(i)            = 0;
        attack_class(i)     = 0;

        %% --- Advance Train Simulation State Machine ---
        cycleCounter = cycleCounter + 1;
        cyclePhase = mod(cycleCounter, trainCycleLength) / trainCycleLength;

        if cyclePhase < 0.10
            % PHASE: IDLE
            sig_state = 3;
            trk_state = 0;
            cur_speed = 0;

        elseif cyclePhase < 0.25
            % PHASE: APPROACHING
            sig_state = 2;
            trk_state = 0;
            targetSpeed = cfg.rail.speedLimit.yellow;
            cur_speed = cur_speed + cfg.rail.maxAccel_ms2 * 3.6 * 0.5;
            if cur_speed > targetSpeed
                cur_speed = targetSpeed;
            end

        elseif cyclePhase < 0.40
            % PHASE: BRAKING
            sig_state = 1;
            trk_state = 1;
            cur_speed = cur_speed - cfg.rail.maxDecel_ms2 * 3.6 * 0.4;
            if cur_speed < 5
                cur_speed = max(0, cur_speed);
            end

        elseif cyclePhase < 0.50
            % PHASE: STOPPED
            sig_state = 1;
            trk_state = 1;
            cur_speed = 0;

        elseif cyclePhase < 0.65
            % PHASE: DEPARTING
            sig_state = 2;
            trk_state = 1;
            cur_speed = cur_speed + cfg.rail.maxAccel_ms2 * 3.6 * 0.3;
            if cur_speed > 60
                cur_speed = 60;
            end

        elseif cyclePhase < 0.90
            % PHASE: RUNNING
            sig_state = 3;
            trk_state = 0;
            targetSpeed = cfg.rail.speedLimit.green;
            cur_speed = cur_speed + cfg.rail.maxAccel_ms2 * 3.6 * 0.2;
            if cur_speed > targetSpeed
                cur_speed = targetSpeed;
            end

        else
            % PHASE: IDLE (inter-train gap)
            sig_state = 3;
            trk_state = 0;
            cur_speed = max(0, cur_speed - cfg.rail.maxDecel_ms2 * 3.6 * 0.5);
        end

        %% --- Switch Position Logic ---
        if trk_state == 0 && randSwitch(i) < 0.02
            sw_state = 1 - sw_state;
        end

        %% --- Update Train Position ---
        train_pos = train_pos + (cur_speed / 3600) * 0.01;
        if train_pos > cfg.rail.numTrackSections * cfg.rail.sectionLength_km
            train_pos = 0;
        end

        %% --- Add Realistic Sensor Noise ---
        noisy_speed = cur_speed + randSpeedNoise(i);
        noisy_speed = max(0, min(cfg.rail.maxSpeed_kmh, noisy_speed));

        %% --- Calculate Movement Authority ---
        switch sig_state
            case 1
                ma_val = 0;
            case 2
                ma_val = 1000 + randMA_yellow(i) * 2000;
            case 3
                ma_val = 5000 + randMA_green(i) * 5000;
            otherwise
                ma_val = 0;
        end

        %% --- Fill Device-Specific Primary Data ---
        switch devType
            case 'signal'
                data_type(i)      = "signal";
                data_value(i)     = sig_state;
                expected_value(i) = sig_state;
            case 'track_circuit'
                data_type(i)      = "track";
                data_value(i)     = trk_state;
                expected_value(i) = trk_state;
            case 'point_machine'
                data_type(i)      = "point";
                data_value(i)     = sw_state;
                expected_value(i) = sw_state;
            case 'axle_counter'
                data_type(i)      = "speed";
                data_value(i)     = noisy_speed;
                expected_value(i) = cur_speed;
            case 'balise'
                data_type(i)      = "balise";
                data_value(i)     = ma_val;
                expected_value(i) = ma_val;
        end

        %% --- Fill State Snapshot Columns ---
        signal_aspect(i)   = sig_state;
        track_occupancy(i) = trk_state;
        switch_position(i) = sw_state;
        speed_data(i)      = noisy_speed;
        balise_ma(i)       = ma_val;

        %% --- Generate Network Parameters ---
        network_latency_ms(i) = cfg.fog.latencyRange_ms(1) + ...
            randLatency(i) * (cfg.fog.latencyRange_ms(2) - cfg.fog.latencyRange_ms(1));
        packet_size_bytes(i) = 64 + randPacketExtra(i);

        %% --- Communication Interval ---
        if i > 1
            timeDiffMs = milliseconds(timestamps(i) - timestamps(i-1));
            comm_interval_ms(i) = max(0, timeDiffMs);
        else
            comm_interval_ms(i) = 10;
        end

        %% --- Progress Report ---
        if mod(i, progressInterval) == 0
            elapsed = toc(lastProgressTime);
            rate = progressInterval / elapsed;
            pct = i / N * 100;
            eta = (N - i) / rate;
            fprintf('      %3.0f%% | %dk/%dk | %.0f samples/sec | ETA: %.0fs\n', ...
                pct, i/1000, N/1000, rate, eta);
            lastProgressTime = tic;
        end

    end  % End main loop

    %% ================================================================
    %  BATCH HASH GENERATION (much faster than per-sample)
    %  ================================================================
    fprintf('    Generating integrity hashes in batch...\n');
    hashTimer = tic;
    
    % Process hashes in chunks to avoid memory issues
    hashBatchSize = 50000;
    nHashBatches = ceil(N / hashBatchSize);
    
    for hb = 1:nHashBatches
        hStart = (hb-1)*hashBatchSize + 1;
        hEnd = min(hb*hashBatchSize, N);
        
        for i = hStart:hEnd
            hashInput = sprintf('%s|%s|%.6f|%.6f|%s', ...
                char(sample_id(i)), ...
                char(string(timestamp(i))), ...
                data_value(i), ...
                expected_value(i), ...
                char(source_device_id(i)));
            integrity_hash(i) = string(hash_generator(hashInput));
        end
        
        if mod(hb, max(1, floor(nHashBatches/5))) == 0 || hb == nHashBatches
            fprintf('      Hash batch %d/%d complete (%.1fs)\n', hb, nHashBatches, toc(hashTimer));
        end
    end

    %% ================================================================
    %  ASSEMBLE INTO TABLE
    %  ================================================================
    fprintf('    Assembling table (%dk rows)...\n', N/1000);
    data = table( ...
        sample_id, ...
        timestamp, ...
        source_device_id, ...
        fog_node_id, ...
        data_type, ...
        data_value, ...
        expected_value, ...
        integrity_hash, ...
        network_latency_ms, ...
        packet_size_bytes, ...
        protocol_type, ...
        signal_aspect, ...
        track_occupancy, ...
        switch_position, ...
        speed_data, ...
        balise_ma, ...
        comm_interval_ms, ...
        label, ...
        attack_type, ...
        attack_class);

    %% ================================================================
    %  VALIDATION AND STATISTICS
    %  ================================================================
    elapsed = toc(timerStart);

    fprintf('  [generate_normal_data] COMPLETE.\n');
    fprintf('    Samples generated : %d (%dk)\n', N, N/1000);
    fprintf('    Generation time   : %.1f seconds (%.0f samples/sec)\n', elapsed, N/elapsed);
    fprintf('    Table columns     : %d\n', width(data));
    fprintf('    Memory estimate   : ~%.0f MB\n', N * 20 * 8 / 1e6);
    fprintf('    ---\n');
    fprintf('    Signal distribution:\n');
    fprintf('      Red (1)    : %6d samples (%5.1f%%)\n', ...
        sum(signal_aspect == 1), 100 * sum(signal_aspect == 1) / N);
    fprintf('      Yellow (2) : %6d samples (%5.1f%%)\n', ...
        sum(signal_aspect == 2), 100 * sum(signal_aspect == 2) / N);
    fprintf('      Green (3)  : %6d samples (%5.1f%%)\n', ...
        sum(signal_aspect == 3), 100 * sum(signal_aspect == 3) / N);
    fprintf('    Track occupancy:\n');
    fprintf('      Clear (0)    : %6d samples (%5.1f%%)\n', ...
        sum(track_occupancy == 0), 100 * sum(track_occupancy == 0) / N);
    fprintf('      Occupied (1) : %6d samples (%5.1f%%)\n', ...
        sum(track_occupancy == 1), 100 * sum(track_occupancy == 1) / N);
    fprintf('    Speed range: %.1f - %.1f km/h (mean: %.1f)\n', ...
        min(speed_data), max(speed_data), mean(speed_data));
    fprintf('    Network latency range: %.1f - %.1f ms (mean: %.1f)\n', ...
        min(network_latency_ms), max(network_latency_ms), mean(network_latency_ms));
    fprintf('    Packet size range: %d - %d bytes\n', ...
        min(packet_size_bytes), max(packet_size_bytes));
    fprintf('    ---\n');

    assert(height(data) == N, 'ERROR: Row count mismatch!');
    assert(all(data.label == 0), 'ERROR: Normal data should have label=0!');
    assert(all(data.speed_data >= 0), 'ERROR: Negative speed detected!');
    assert(all(data.signal_aspect >= 1 & data.signal_aspect <= 3), ...
        'ERROR: Invalid signal aspect!');
    assert(all(data.track_occupancy == 0 | data.track_occupancy == 1), ...
        'ERROR: Invalid track occupancy!');
    assert(all(data.switch_position == 0 | data.switch_position == 1), ...
        'ERROR: Invalid switch position!');

    fprintf('    All validation checks PASSED.\n\n');
end


%% ========================================================================
%  LOCAL HELPER: GENERATE TIME DISTRIBUTION
%  Extended for 14 days coverage with 700K samples
%% ========================================================================
function timestamps = generate_time_distribution_local(N, baseDate)

    hourWeights = [ ...
        0.5, 0.5, 0.2, 0.2, 0.5, 1.0, ...
        2.0, 5.0, 6.0, 4.0, 3.0, 2.5, ...
        3.0, 2.5, 2.5, 3.0, 4.0, 5.0, ...
        5.0, 3.0, 2.0, 1.5, 1.0, 0.5  ...
    ];

    hourWeights = hourWeights / sum(hourWeights);
    cumWeights = cumsum(hourWeights);

    % For 1M scale, spread across 14 days
    numDays = 14;
    samplesPerDay = ceil(N / numDays);
    
    fprintf('      Generating timestamps across %d days (%dk/day)...\n', numDays, samplesPerDay/1000);
    
    allTimestamps = NaT(N, 1);
    idx = 0;
    
    for day = 0:(numDays-1)
        dayBase = baseDate + days(day);
        nThisDay = min(samplesPerDay, N - idx);
        if nThisDay <= 0, break; end
        
        % Generate hours weighted by distribution
        randomValues = rand(nThisDay, 1);
        hours = zeros(nThisDay, 1);
        for i = 1:nThisDay
            hours(i) = find(cumWeights >= randomValues(i), 1, 'first') - 1;
        end
        hours = sort(hours);
        
        mins = randi([0, 59], nThisDay, 1);
        secs = rand(nThisDay, 1) * 60;
        
        dayTimestamps = dayBase + duration(hours, mins, secs);
        dayTimestamps = sort(dayTimestamps);
        
        allTimestamps(idx+1 : idx+nThisDay) = dayTimestamps;
        idx = idx + nThisDay;
    end
    
    timestamps = allTimestamps(1:N);
    timestamps = sort(timestamps);
end