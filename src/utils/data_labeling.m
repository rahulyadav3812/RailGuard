%% ========================================================================
% FILE: data_labeling.m
% DESCRIPTION: Combines normal and attack data, shuffles, creates final dataset.
%              Handles potential column type mismatches between tables.
%
% HOW TO RUN:
%   fullData = data_labeling(cfg, normalData, attackData);
%% ========================================================================

function fullData = data_labeling(cfg, normalData, attackData)

    fprintf('  [data_labeling] Combining and labeling dataset...\n');

    %% Check column compatibility
    normalCols = normalData.Properties.VariableNames;
    attackCols = attackData.Properties.VariableNames;

    % Verify same columns exist
    if ~isequal(sort(normalCols), sort(attackCols))
        fprintf('    WARNING: Column mismatch detected. Finding common columns...\n');

        % Find common columns
        commonCols = intersect(normalCols, attackCols, 'stable');
        fprintf('    Using %d common columns out of %d/%d\n', ...
            length(commonCols), length(normalCols), length(attackCols));

        % Missing from each
        missingInAttack = setdiff(normalCols, attackCols);
        missingInNormal = setdiff(attackCols, normalCols);
        if ~isempty(missingInAttack)
            fprintf('    Columns missing in attack data: %s\n', strjoin(missingInAttack, ', '));
        end
        if ~isempty(missingInNormal)
            fprintf('    Columns missing in normal data: %s\n', strjoin(missingInNormal, ', '));
        end

        normalData = normalData(:, commonCols);
        attackData = attackData(:, commonCols);
    end

    %% Ensure column order matches
    attackData = attackData(:, normalData.Properties.VariableNames);

    %% Force matching data types for each column
    colNames = normalData.Properties.VariableNames;
    for c = 1:length(colNames)
        col = colNames{c};
        normalType = class(normalData.(col));
        attackType = class(attackData.(col));

        if ~strcmp(normalType, attackType)
            fprintf('    Fixing type mismatch: %s (normal=%s, attack=%s)\n', ...
                col, normalType, attackType);

            % Convert attack column to match normal column type
            try
                switch normalType
                    case 'string'
                        attackData.(col) = string(attackData.(col));
                    case 'double'
                        attackData.(col) = double(attackData.(col));
                    case 'cell'
                        if isstring(attackData.(col))
                            attackData.(col) = cellstr(attackData.(col));
                        end
                    case 'datetime'
                        attackData.(col) = datetime(attackData.(col));
                    otherwise
                        % Try generic cast
                        attackData.(col) = cast(attackData.(col), normalType);
                end
            catch ME
                fprintf('    Could not auto-fix column %s: %s\n', col, ME.message);
            end
        end
    end

    %% Now combine
    try
        fullData = [normalData; attackData];
    catch ME
        % If still fails, build manually column by column
        fprintf('    Direct concatenation failed. Building manually...\n');
        
        Nn = height(normalData);
        Na = height(attackData);
        Nt = Nn + Na;
        
        % Initialize with normal data
        fullData = normalData;
        
        % Append attack data row by row using common approach
        for c = 1:length(colNames)
            col = colNames{c};
            try
                normalCol = normalData.(col);
                attackCol = attackData.(col);
                
                if isstring(normalCol) || iscell(normalCol)
                    fullData.(col) = [string(normalCol); string(attackCol)];
                elseif isdatetime(normalCol)
                    fullData.(col) = [normalCol; attackCol];
                elseif isnumeric(normalCol)
                    fullData.(col) = [double(normalCol); double(attackCol)];
                else
                    fullData.(col) = [normalCol; attackCol];
                end
            catch
                fprintf('    Skipping problematic column: %s\n', col);
            end
        end
    end

    %% Shuffle
    rng(cfg.seed + 200, 'twister');
    shuffleIdx = randperm(height(fullData));
    fullData = fullData(shuffleIdx, :);

    %% Re-index
    for i = 1:height(fullData)
        fullData.sample_id(i) = sprintf("S%06d", i);
    end

    %% Summary
    nNormal = sum(fullData.label == 0);
    nAttack = sum(fullData.label == 1);
    fprintf('    Total samples: %d (Normal: %d, Attack: %d)\n', ...
        height(fullData), nNormal, nAttack);
    fprintf('    Attack ratio: %.1f%%\n', 100 * nAttack / height(fullData));

    attackTypes = unique(fullData.attack_type);
    for t = 1:length(attackTypes)
        at = attackTypes(t);
        n = sum(fullData.attack_type == at);
        fprintf('      %-12s: %5d samples\n', at, n);
    end
    
    fprintf('  [data_labeling] COMPLETE. Final table: %d rows x %d columns.\n', ...
        height(fullData), width(fullData));
end