%% ========================================================================
% FILE: generate_attack_data.m
% DESCRIPTION: Generates 300,000 attack samples across 6 types
%              Preserves all per-type logic, adds progress reporting
%% ========================================================================

function attackData = generate_attack_data(cfg, normalData)

    fprintf('  [generate_attack_data] Starting generation of %d attack samples...\n', ...
        cfg.data.totalAttackSamples);
    timerStart = tic;
    rng(cfg.seed + 100, 'twister');
    Nn = height(normalData);

    %% Generate each attack type
    fprintf('    [1/6] False Data Injection (FDI): %dk samples\n', cfg.data.attackSamples.FDI/1000);
    fdi = gen_FDI(cfg, normalData, Nn);
    fprintf('      Done. (%.1fs)\n', toc(timerStart));

    fprintf('    [2/6] Replay Attack: %dk samples\n', cfg.data.attackSamples.replay/1000);
    t2=tic; rep = gen_Replay(cfg, normalData, Nn);
    fprintf('      Done. (%.1fs)\n', toc(t2));

    fprintf('    [3/6] Man-in-the-Middle (MITM): %dk samples\n', cfg.data.attackSamples.MITM/1000);
    t3=tic; mitm = gen_MITM(cfg, normalData, Nn);
    fprintf('      Done. (%.1fs)\n', toc(t3));

    fprintf('    [4/6] Denial of Service (DoS): %dk samples\n', cfg.data.attackSamples.DoS/1000);
    t4=tic; dos = gen_DoS(cfg, normalData, Nn);
    fprintf('      Done. (%.1fs)\n', toc(t4));

    fprintf('    [5/6] Signal Spoofing: %dk samples\n', cfg.data.attackSamples.spoofing/1000);
    t5=tic; spoof = gen_Spoofing(cfg, normalData, Nn);
    fprintf('      Done. (%.1fs)\n', toc(t5));

    fprintf('    [6/6] Command Manipulation: %dk samples\n', cfg.data.attackSamples.cmdManip/1000);
    t6=tic; cmd = gen_CmdManip(cfg, normalData, Nn);
    fprintf('      Done. (%.1fs)\n', toc(t6));

    %% Combine all
    fprintf('    Combining all attack types...\n');
    attackData = [fdi; rep; mitm; dos; spoof; cmd];
    
    % Free individual tables
    clear fdi rep mitm dos spoof cmd;

    % Re-index sample IDs
    fprintf('    Assigning %dk sample IDs...\n', height(attackData)/1000);
    for i = 1:height(attackData)
        attackData.sample_id(i) = sprintf("A%07d", i);
    end

    elapsed = toc(timerStart);
    fprintf('  [generate_attack_data] Done. %dk samples in %.1f seconds.\n', ...
        height(attackData)/1000, elapsed);

    types = unique(attackData.attack_type);
    fprintf('    Attack distribution:\n');
    for t = 1:length(types)
        cnt = sum(attackData.attack_type == types(t));
        fprintf('      %-12s: %6dk samples\n', types(t), cnt/1000);
    end
end

%% ========================================================================
%  ATTACK TYPE 1: FALSE DATA INJECTION (FDI) - 120,000 samples
%% ========================================================================
function out = gen_FDI(cfg, normalData, Nn)
    N = cfg.data.attackSamples.FDI;
    idx = randi(Nn, N, 1);
    out = normalData(idx, :);
    
    % Pre-generate random values
    randHash = rand(N, 1);
    randLatExtra = rand(N, 1) * 8;
    
    progressN = max(1, floor(N/5));

    for i = 1:N
        out.label(i) = 1;
        out.attack_type(i) = "FDI";
        out.attack_class(i) = 1;
        variant = mod(i, 5) + 1;

        switch variant
            case 1
                out.data_type(i) = "signal";
                out.expected_value(i) = 1;
                out.data_value(i) = 3;
                out.signal_aspect(i) = 3;
            case 2
                out.data_type(i) = "track";
                out.expected_value(i) = 1;
                out.data_value(i) = 0;
                out.track_occupancy(i) = 0;
            case 3
                out.data_type(i) = "speed";
                safeSpeed = cfg.rail.speedLimit.yellow;
                out.expected_value(i) = safeSpeed;
                out.data_value(i) = safeSpeed + 40 + randi(80);
                out.speed_data(i) = out.data_value(i);
            case 4
                out.data_type(i) = "balise";
                out.expected_value(i) = 0;
                out.data_value(i) = 6000 + randi(5000);
                out.balise_ma(i) = out.data_value(i);
            case 5
                out.data_type(i) = "point";
                out.expected_value(i) = 0;
                out.data_value(i) = 1;
                out.switch_position(i) = 1;
        end

        if randHash(i) < 0.7
            out.integrity_hash(i) = string(hash_generator(sprintf('FDI_%d_%f', i, rand())));
        end
        out.network_latency_ms(i) = out.network_latency_ms(i) + randLatExtra(i);
        
        if mod(i, progressN) == 0
            fprintf('        FDI: %d%% complete\n', round(i/N*100));
        end
    end
end

%% ========================================================================
%  ATTACK TYPE 2: REPLAY ATTACK - 50,000 samples
%% ========================================================================
function out = gen_Replay(cfg, normalData, Nn)
    N = cfg.data.attackSamples.replay;
    idx = randi(Nn, N, 1);
    out = normalData(idx, :);
    
    progressN = max(1, floor(N/5));

    for i = 1:N
        out.label(i) = 1;
        out.attack_type(i) = "replay";
        out.attack_class(i) = 2;
        variant = mod(i, 3) + 1;

        switch variant
            case 1
                replayAge = seconds(30 + randi(270));
                out.timestamp(i) = out.timestamp(i) - replayAge;
                out.network_latency_ms(i) = out.network_latency_ms(i) + 30 + rand()*50;
            case 2
                srcIdx = max(1, idx(i) - randi(50));
                out.integrity_hash(i) = normalData.integrity_hash(srcIdx);
                out.data_value(i) = normalData.data_value(srcIdx);
                out.expected_value(i) = out.data_value(i) + sign(randn()) * (5 + randi(20));
            case 3
                out.data_type(i) = "balise";
                out.data_value(i) = normalData.data_value(idx(i));
                out.expected_value(i) = 0;
                out.balise_ma(i) = out.data_value(i);
        end
        out.comm_interval_ms(i) = out.comm_interval_ms(i) + 500 + rand()*2000;
        
        if mod(i, progressN) == 0
            fprintf('        Replay: %d%% complete\n', round(i/N*100));
        end
    end
end

%% ========================================================================
%  ATTACK TYPE 3: MAN-IN-THE-MIDDLE (MITM) - 40,000 samples
%% ========================================================================
function out = gen_MITM(cfg, normalData, Nn)
    N = cfg.data.attackSamples.MITM;
    idx = randi(Nn, N, 1);
    out = normalData(idx, :);
    
    progressN = max(1, floor(N/5));

    for i = 1:N
        out.label(i) = 1;
        out.attack_type(i) = "MITM";
        out.attack_class(i) = 3;
        variant = mod(i, 4) + 1;

        switch variant
            case 1
                out.data_type(i) = "signal";
                origSig = out.data_value(i);
                possible = setdiff([1 2 3], origSig);
                out.data_value(i) = possible(randi(length(possible)));
                out.signal_aspect(i) = out.data_value(i);
            case 2
                out.data_type(i) = "point";
                out.data_value(i) = 1 - out.data_value(i);
                out.switch_position(i) = out.data_value(i);
            case 3
                out.data_type(i) = "speed";
                modification = (rand() - 0.3) * 80;
                out.data_value(i) = max(0, out.data_value(i) + modification);
                out.speed_data(i) = out.data_value(i);
            case 4
                out.data_type(i) = "balise";
                out.data_value(i) = out.data_value(i) * (1.5 + rand());
                out.balise_ma(i) = out.data_value(i);
        end

        out.network_latency_ms(i) = out.network_latency_ms(i) + 10 + rand() * 40;
        out.packet_size_bytes(i) = max(40, out.packet_size_bytes(i) + randi([-15, 25]));

        if rand() >= 0.4
            out.integrity_hash(i) = string(hash_generator(sprintf('MITM_%d_%f', i, rand())));
        end
        
        if mod(i, progressN) == 0
            fprintf('        MITM: %d%% complete\n', round(i/N*100));
        end
    end
end

%% ========================================================================
%  ATTACK TYPE 4: DENIAL OF SERVICE (DoS) - 40,000 samples
%% ========================================================================
function out = gen_DoS(cfg, normalData, Nn)
    N = cfg.data.attackSamples.DoS;
    idx = randi(Nn, N, 1);
    out = normalData(idx, :);
    
    progressN = max(1, floor(N/5));

    for i = 1:N
        out.label(i) = 1;
        out.attack_type(i) = "DoS";
        out.attack_class(i) = 4;
        variant = mod(i, 4) + 1;

        switch variant
            case 1
                out.packet_size_bytes(i) = 20 + randi(44);
                out.network_latency_ms(i) = 200 + rand() * 800;
                out.data_value(i) = 0;
                out.comm_interval_ms(i) = rand() * 2;
            case 2
                out.packet_size_bytes(i) = 1500 + randi(5000);
                out.network_latency_ms(i) = 300 + rand() * 700;
                out.comm_interval_ms(i) = rand() * 5;
            case 3
                out.packet_size_bytes(i) = 64 + randi(200);
                out.network_latency_ms(i) = 1000 + rand() * 4000;
                out.comm_interval_ms(i) = 5000 + rand() * 10000;
            case 4
                out.packet_size_bytes(i) = 200 + randi(300);
                out.network_latency_ms(i) = 100 + rand() * 400;
                out.comm_interval_ms(i) = rand() * 1;
        end

        if i > 1
            out.timestamp(i) = out.timestamp(max(1,i-1)) + milliseconds(randi(5));
        end

        if rand() < 0.4
            out.data_type(i) = "unknown";
            out.data_value(i) = rand() * 99999;
        end
        out.integrity_hash(i) = string(hash_generator(sprintf('DoS_%d_%f', i, rand())));
        
        if mod(i, progressN) == 0
            fprintf('        DoS: %d%% complete\n', round(i/N*100));
        end
    end
end

%% ========================================================================
%  ATTACK TYPE 5: SIGNAL SPOOFING - 30,000 samples
%% ========================================================================
function out = gen_Spoofing(cfg, normalData, Nn)
    N = cfg.data.attackSamples.spoofing;
    idx = randi(Nn, N, 1);
    out = normalData(idx, :);

    fakeDevices = ["ED_FAKE1","ED_FAKE2","ED_SPOOF","XX999","ED_CLN01"];
    fakeFogs = ["FN_FAKE","FN_SPOOF","FN999"];
    
    progressN = max(1, floor(N/5));

    for i = 1:N
        out.label(i) = 1;
        out.attack_type(i) = "spoofing";
        out.attack_class(i) = 5;
        variant = mod(i, 4) + 1;

        switch variant
            case 1
                out.data_type(i) = "signal";
                out.data_value(i) = 3;
                out.expected_value(i) = 1;
                out.signal_aspect(i) = 3;
                out.source_device_id(i) = fakeDevices(randi(length(fakeDevices)));
            case 2
                out.data_type(i) = "balise";
                out.data_value(i) = 8000 + randi(5000);
                out.expected_value(i) = 0;
                out.balise_ma(i) = out.data_value(i);
                out.source_device_id(i) = fakeDevices(randi(length(fakeDevices)));
            case 3
                legitimateDevs = string(cfg.edge.devices.id);
                out.source_device_id(i) = legitimateDevs(randi(length(legitimateDevs)));
                out.data_value(i) = out.expected_value(i) + 20 + randi(50);
            case 4
                out.data_type(i) = "track";
                out.data_value(i) = 0;
                out.expected_value(i) = 1;
                out.track_occupancy(i) = 0;
                out.source_device_id(i) = fakeDevices(randi(length(fakeDevices)));
        end

        if rand() < 0.6
            out.fog_node_id(i) = fakeFogs(randi(length(fakeFogs)));
        end

        if rand() < 0.5
            out.network_latency_ms(i) = rand() * 1;
        else
            out.network_latency_ms(i) = 50 + rand() * 100;
        end
        
        if mod(i, progressN) == 0
            fprintf('        Spoofing: %d%% complete\n', round(i/N*100));
        end
    end
end

%% ========================================================================
%  ATTACK TYPE 6: COMMAND MANIPULATION - 20,000 samples
%% ========================================================================
function out = gen_CmdManip(cfg, normalData, Nn)
    N = cfg.data.attackSamples.cmdManip;
    idx = randi(Nn, N, 1);
    out = normalData(idx, :);
    
    progressN = max(1, floor(N/5));

    for i = 1:N
        out.label(i) = 1;
        out.attack_type(i) = "cmdManip";
        out.attack_class(i) = 6;
        variant = mod(i, 4) + 1;

        switch variant
            case 1
                out.data_type(i) = "point";
                out.data_value(i) = 1 - out.expected_value(i);
                out.switch_position(i) = out.data_value(i);
                out.expected_value(i) = 1 - out.data_value(i);
            case 2
                out.data_type(i) = "signal";
                out.data_value(i) = 3;
                out.expected_value(i) = 1;
                out.signal_aspect(i) = 3;
            case 3
                out.data_type(i) = "speed";
                out.expected_value(i) = 0;
                out.data_value(i) = 80 + randi(60);
                out.speed_data(i) = out.data_value(i);
            case 4
                out.data_type(i) = "balise";
                out.expected_value(i) = 0;
                out.data_value(i) = 3000 + randi(7000);
                out.balise_ma(i) = out.data_value(i);
        end

        out.integrity_hash(i) = string(hash_generator(sprintf('CMD_%d_%f', i, rand())));
        out.network_latency_ms(i) = out.network_latency_ms(i) + 3 + rand() * 15;
        out.packet_size_bytes(i) = max(40, out.packet_size_bytes(i) + randi([-5 15]));
        
        if mod(i, progressN) == 0
            fprintf('        CmdManip: %d%% complete\n', round(i/N*100));
        end
    end
end