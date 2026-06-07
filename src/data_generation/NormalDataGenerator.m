classdef NormalDataGenerator
    properties
        cfg;
    end
    methods
        function obj = NormalDataGenerator(cfg)
            obj.cfg = cfg;
        end
        function data = generate(obj)
            data = generate_normal_data(obj.cfg);
        end
    end
end