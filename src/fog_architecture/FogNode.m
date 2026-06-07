classdef FogNode
    % FogNode - Simulates fog computing node with ML detection
    
    properties
        id
        type
        status
        assignedEdges
        samplesProcessed
        alertsGenerated
        avgLatency
        latencyHistory
        cpuUtilization
        memoryUsage
    end
    
    methods
        function obj = FogNode(id, type, assignedEdges)
            obj.id = id;
            obj.type = type;
            obj.assignedEdges = assignedEdges;
            obj.status = 'active';
            obj.samplesProcessed = 0;
            obj.alertsGenerated = 0;
            obj.avgLatency = 0;
            obj.latencyHistory = [];
            obj.cpuUtilization = 0.3 + rand()*0.3;
            obj.memoryUsage = 0.2 + rand()*0.3;
        end
        
        function [obj, result] = processData(obj, dataRow, statMu, statSigma)
            t = tic;
            result = struct();
            result.fogNodeID = obj.id;
            result.timestamp = datetime('now');
            
            zScores = abs((dataRow - statMu) ./ statSigma);
            result.anomalyScore = max(zScores);
            result.isAnomaly = result.anomalyScore > 2.5;
            result.latency_ms = toc(t) * 1000;
            
            obj.latencyHistory(end+1) = result.latency_ms;
            if length(obj.latencyHistory) > 1000
                obj.latencyHistory = obj.latencyHistory(end-999:end);
            end
            obj.avgLatency = mean(obj.latencyHistory);
            obj.samplesProcessed = obj.samplesProcessed + 1;
            if result.isAnomaly
                obj.alertsGenerated = obj.alertsGenerated + 1;
            end
        end
        
        function [obj, results] = processBatch(obj, dataBatch, statMu, statSigma)
            t = tic;
            zScores = abs((dataBatch - statMu) ./ statSigma);
            maxZ = max(zScores, [], 2);
            batchTime = toc(t) * 1000;
            
            nSamples = size(dataBatch, 1);
            anomalies = maxZ > 2.5;
            
            results = struct();
            results.anomalyScores = maxZ;
            results.isAnomaly = anomalies;
            results.totalLatency_ms = batchTime;
            results.perSampleLatency_ms = batchTime / nSamples;
            
            obj.samplesProcessed = obj.samplesProcessed + nSamples;
            obj.alertsGenerated = obj.alertsGenerated + sum(anomalies);
            obj.avgLatency = batchTime / nSamples;
        end
        
        function stats = getStats(obj)
            stats = struct('id',obj.id, 'type',obj.type, 'status',obj.status, ...
                'processed',obj.samplesProcessed, 'alerts',obj.alertsGenerated, ...
                'avgLatency_ms',obj.avgLatency, 'cpu',obj.cpuUtilization, ...
                'memory',obj.memoryUsage);
            if obj.samplesProcessed > 0
                stats.alertRate = obj.alertsGenerated / obj.samplesProcessed;
            else
                stats.alertRate = 0;
            end
        end
    end
end