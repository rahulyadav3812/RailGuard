classdef CloudServer
    % CloudServer - Cloud tier for aggregation, monitoring, retraining
    
    properties
        status
        totalAlerts
        alertLog
        modelVersion
        lastSync
        connectedFogNodes
        retrainingHistory
        storageUsed_GB
    end
    
    methods
        function obj = CloudServer()
            obj.status = 'connected';
            obj.totalAlerts = 0;
            obj.alertLog = {};
            obj.modelVersion = '1.0';
            obj.lastSync = datetime('now');
            obj.connectedFogNodes = {};
            obj.retrainingHistory = {};
            obj.storageUsed_GB = 2.5;
        end
        
        function obj = registerFogNode(obj, fogNodeID)
            if ~ismember(fogNodeID, obj.connectedFogNodes)
                obj.connectedFogNodes{end+1} = fogNodeID;
            end
        end
        
        function obj = receiveAlerts(obj, alerts, fogNodeID)
            nAlerts = length(alerts);
            obj.totalAlerts = obj.totalAlerts + nAlerts;
            entry = struct('fogNode',fogNodeID,'count',nAlerts,...
                'time',datetime('now'));
            obj.alertLog{end+1} = entry;
            obj.lastSync = datetime('now');
            obj.storageUsed_GB = obj.storageUsed_GB + nAlerts*0.001;
        end
        
        function obj = triggerRetraining(obj, reason)
            vParts = strsplit(obj.modelVersion, '.');
            minor = str2double(vParts{2}) + 1;
            oldVer = obj.modelVersion;
            obj.modelVersion = sprintf('%s.%d', vParts{1}, minor);
            entry = struct('time',datetime('now'),'reason',reason,...
                'from',oldVer,'to',obj.modelVersion);
            obj.retrainingHistory{end+1} = entry;
            fprintf('    Cloud: Retrained %s -> %s (%s)\n', oldVer, obj.modelVersion, reason);
        end
        
        function stats = getStats(obj)
            stats = struct('status',obj.status, 'alerts',obj.totalAlerts, ...
                'version',obj.modelVersion, 'fogNodes',length(obj.connectedFogNodes), ...
                'storage_GB',obj.storageUsed_GB, 'retrains',length(obj.retrainingHistory));
        end
        
        function printDashboard(obj)
            fprintf('\n  ══════ CLOUD DASHBOARD ══════\n');
            fprintf('  Status:    %s\n', obj.status);
            fprintf('  Alerts:    %d\n', obj.totalAlerts);
            fprintf('  Model:     v%s\n', obj.modelVersion);
            fprintf('  Fog Nodes: %d\n', length(obj.connectedFogNodes));
            fprintf('  Storage:   %.1f GB\n', obj.storageUsed_GB);
            fprintf('  ═════════════════════════════\n');
        end
    end
end