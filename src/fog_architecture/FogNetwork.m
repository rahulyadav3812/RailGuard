classdef FogNetwork
    % FogNetwork - Orchestrates entire 3-tier fog architecture
    
    properties
        edgeDevices
        fogNodes
        cloudServer
        cfg
    end
    
    methods
        function obj = FogNetwork(cfg)
            obj.cfg = cfg;
            
            % Create edge devices
            for e = 1:cfg.edge.numDevices
                obj.edgeDevices(e) = EdgeDevice(...
                    cfg.edge.devices.id{e}, ...
                    cfg.edge.devices.name{e}, ...
                    cfg.edge.devices.type{e});
            end
            
            % Create fog nodes
            for f = 1:cfg.fog.numNodes
                obj.fogNodes(f) = FogNode(...
                    cfg.fog.nodes.id{f}, ...
                    cfg.fog.nodes.type{f}, ...
                    cfg.fog.nodes.edgeMap{f});
            end
            
            % Assign edges to fog nodes
            for f = 1:cfg.fog.numNodes
                for e = 1:length(cfg.fog.nodes.edgeMap{f})
                    edgeID = cfg.fog.nodes.edgeMap{f}{e};
                    for ed = 1:length(obj.edgeDevices)
                        if strcmp(obj.edgeDevices(ed).id, edgeID)
                            obj.edgeDevices(ed) = obj.edgeDevices(ed).assignToFog(cfg.fog.nodes.id{f});
                        end
                    end
                end
            end
            
            % Create cloud
            obj.cloudServer = CloudServer();
            for f = 1:cfg.fog.numNodes
                obj.cloudServer = obj.cloudServer.registerFogNode(cfg.fog.nodes.id{f});
            end
        end
        
        function [obj, avgLatency] = simulateDataFlow(obj, nSamples)
            fprintf('  Simulating %d transmissions...\n', nSamples);
            latencies = zeros(nSamples, 1);
            
            for s = 1:nSamples
                edgeIdx = mod(s-1, length(obj.edgeDevices)) + 1;
                fogIdx = mod(edgeIdx-1, length(obj.fogNodes)) + 1;
                
                e2f = obj.cfg.fog.latencyRange_ms(1) + rand()*diff(obj.cfg.fog.latencyRange_ms);
                proc = obj.cfg.fog.processingDelay_ms(1) + rand()*diff(obj.cfg.fog.processingDelay_ms);
                latencies(s) = e2f + proc;
                
                obj.edgeDevices(edgeIdx).packetsGenerated = obj.edgeDevices(edgeIdx).packetsGenerated + 1;
                obj.fogNodes(fogIdx).samplesProcessed = obj.fogNodes(fogIdx).samplesProcessed + 1;
            end
            
            avgLatency = mean(latencies);
            fprintf('    Avg: %.2f ms, Max: %.2f ms\n', avgLatency, max(latencies));
        end
        
        function printStatus(obj)
            fprintf('\n  === NETWORK STATUS ===\n');
            fprintf('  Edge Devices (%d):\n', length(obj.edgeDevices));
            for e = 1:length(obj.edgeDevices)
                d = obj.edgeDevices(e);
                fprintf('    [%s] %s (%s) - %d pkts\n', d.id, d.name, d.status, d.packetsGenerated);
            end
            fprintf('  Fog Nodes (%d):\n', length(obj.fogNodes));
            for f = 1:length(obj.fogNodes)
                n = obj.fogNodes(f);
                fprintf('    [%s] %s - %d processed, %d alerts\n', n.id, n.type, n.samplesProcessed, n.alertsGenerated);
            end
            obj.cloudServer.printDashboard();
        end
    end
end