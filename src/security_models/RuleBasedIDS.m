classdef RuleBasedIDS
    properties
        threshold;
        ruleDescriptions;
    end
    methods
        function obj = RuleBasedIDS()
            obj.threshold = 3;
            obj.ruleDescriptions = {
                'R01: Deviation norm > 1.0'
                'R02: Deviation pct > 1.0'
                'R03: Hash validation failed'
                'R04: Unknown device ID'
                'R05: Unknown fog node'
                'R06: High latency'
                'R07: Low latency'
                'R08: Oversized packet'
                'R09: Comm interval high'
                'R10: Signal-speed violated'
                'R11: Track-signal violated'
                'R12: Deviation + hash combined'
                'R13: Device + deviation combined'
                'R14: Multiple mild flags'
                'R15: Speed outside safe range'
                'R16: MA exceeded'
                'R17: Telegram corrupted'
                'R18: Emergency brake anomaly'
                'R19: Repeated sequence'
                'R20: Timestamp anomaly'};
        end
        function pred = predict(obj, XTest)
            n = size(XTest, 1);
            pred = zeros(n, 1);
            for i = 1:n
                v = 0;
                if XTest(i,3)>1.0, v=v+2; end
                if XTest(i,4)>1.0, v=v+2; end
                if XTest(i,13)<-0.2, v=v+3; end
                if XTest(i,14)<-1.2, v=v+3; end
                if XTest(i,15)<-1.2, v=v+2; end
                if XTest(i,10)>1.5, v=v+2; end
                if XTest(i,10)<-1.5, v=v+1; end
                if XTest(i,11)>2.5, v=v+2; end
                if XTest(i,12)>1.5, v=v+2; end
                if XTest(i,17)<-0.2, v=v+3; end
                if XTest(i,18)<-0.2, v=v+3; end
                if XTest(i,3)>0.8 && XTest(i,13)<0, v=v+3; end
                if XTest(i,14)<-0.8 && XTest(i,3)>0.3, v=v+3; end
                mf = (XTest(i,3)>0.5)+(XTest(i,13)<0)+(XTest(i,10)>0.8)+(XTest(i,17)<0)+(XTest(i,18)<0)+(XTest(i,14)<-0.3);
                if mf>=2, v=v+3; end
                if v >= obj.threshold, pred(i)=1; end
            end
        end
    end
end