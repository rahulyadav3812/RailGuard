classdef EdgeDevice
    % EdgeDevice - Simulates railway field edge devices
    % Represents signals, track circuits, points, axle counters, balises
    
    properties
        id
        name
        type
        status
        assignedFog
        packetsGenerated
        lastTimestamp
        encryptionEnabled
    end
    
    methods
        function obj = EdgeDevice(id, name, type)
            obj.id = id;
            obj.name = name;
            obj.type = type;
            obj.status = 'active';
            obj.assignedFog = '';
            obj.packetsGenerated = 0;
            obj.lastTimestamp = datetime('now');
            obj.encryptionEnabled = true;
        end
        
        function [obj, packet] = generateData(obj)
            packet = struct();
            packet.sourceID = obj.id;
            packet.timestamp = datetime('now');
            packet.deviceType = obj.type;
            
            switch obj.type
                case 'signal'
                    packet.aspect = randi([0 3]);
                    speeds = [0, 40, 80, 120];
                    packet.speed_limit = speeds(packet.aspect + 1);
                case 'track_circuit'
                    packet.occupied = randi([0 1]);
                    packet.rail_voltage = 5.0 + randn() * 0.1;
                case 'points'
                    packet.position = randi([0 1]);
                    packet.locked = 1;
                    packet.detection = 1;
                case 'axle_counter'
                    packet.count_in = randi([0 50]);
                    packet.count_out = packet.count_in;
                    packet.section_clear = 1;
                case 'balise'
                    packet.telegram = randi([0 255], 1, 32);
                    packet.linking_distance = randi([100 5000]);
            end
            
            packet.hash = mod(sum(double(char(obj.id))) * 31, 2^32);
            packet.encrypted = obj.encryptionEnabled;
            obj.packetsGenerated = obj.packetsGenerated + 1;
            obj.lastTimestamp = packet.timestamp;
        end
        
        function obj = assignToFog(obj, fogID)
            obj.assignedFog = fogID;
        end
        
        function obj = setStatus(obj, newStatus)
            obj.status = newStatus;
        end
        
        function info = getInfo(obj)
            info = struct('id',obj.id, 'name',obj.name, 'type',obj.type, ...
                'status',obj.status, 'packets',obj.packetsGenerated, ...
                'fog',obj.assignedFog);
        end
    end
end