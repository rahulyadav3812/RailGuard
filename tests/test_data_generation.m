function test_data_generation()
    fprintf('TEST: Data Generation\n');
    passed = 0; total = 0;
    
    cfg = config();
    rng(cfg.seed);
    
    try
        total=total+1;
        normalData = generate_normal_data(cfg);
        assert(height(normalData) == cfg.data.numNormalSamples);
        passed=passed+1; fprintf('  ✓ Normal data: %d rows\n', height(normalData));
        
        total=total+1;
        assert(all(normalData.label == 0));
        passed=passed+1; fprintf('  ✓ All normal labels = 0\n');
        
        total=total+1;
        attackData = generate_attack_data(cfg, normalData);
        assert(height(attackData) > 0);
        passed=passed+1; fprintf('  ✓ Attack data: %d rows\n', height(attackData));
        
        total=total+1;
        assert(all(attackData.label == 1));
        passed=passed+1; fprintf('  ✓ All attack labels = 1\n');
        
        total=total+1;
        assert(max(attackData.attack_class) == 6);
        passed=passed+1; fprintf('  ✓ 6 attack types present\n');
    catch ME
        fprintf('  ✗ FAILED: %s\n', ME.message);
    end
    
    fprintf('  Result: %d/%d passed\n\n', passed, total);
end