function test_config()
    fprintf('TEST: Configuration\n');
    passed = 0; total = 0;
    
    try
        cfg = config();
        total=total+1; assert(cfg.seed == 42); passed=passed+1; fprintf('  ✓ Seed=42\n');
        total=total+1; assert(cfg.data.numNormalSamples == 10000); passed=passed+1; fprintf('  ✓ Normal=10000\n');
        total=total+1; assert(cfg.data.totalAttackSamples == 5000); passed=passed+1; fprintf('  ✓ Attack=5000\n');
        total=total+1; assert(cfg.edge.numDevices > 0); passed=passed+1; fprintf('  ✓ Edge devices exist\n');
        total=total+1; assert(cfg.fog.numNodes > 0); passed=passed+1; fprintf('  ✓ Fog nodes exist\n');
        total=total+1; assert(cfg.ml.rf.numTrees > 0); passed=passed+1; fprintf('  ✓ RF trees configured\n');
    catch ME
        fprintf('  ✗ FAILED: %s\n', ME.message);
    end
    
    fprintf('  Result: %d/%d passed\n\n', passed, total);
end