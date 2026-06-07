classdef AttackDataGenerator
    properties
        cfg;
        attackTypes;
    end
    methods
        function obj = AttackDataGenerator(cfg)
            obj.cfg = cfg;
            obj.attackTypes = {'FDI','Replay','MITM','DoS','Spoofing','CmdManip'};
        end
        function data = generate(obj, normalData)
            data = generate_attack_data(obj.cfg, normalData);
        end
    end
end