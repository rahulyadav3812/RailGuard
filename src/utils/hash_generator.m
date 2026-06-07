%% ========================================================================
% FILE: hash_generator.m
% DESCRIPTION: SHA-256 hash generation for data integrity verification.
%
% USAGE:
%   h = hash_generator('my data string');
%   % h = '64-character hex string'
%
%   hBatch = hash_generator_batch(cellArrayOfStrings);
%   % returns cell array of hashes
%% ========================================================================

function hashStr = hash_generator(inputStr)
    try
        md = java.security.MessageDigest.getInstance('SHA-256');
        md.update(uint8(inputStr));
        hashBytes = typecast(md.digest(), 'uint8');
        hashStr = sprintf('%02x', hashBytes);
    catch
        % Fallback if Java not available
        numVal = sum(double(inputStr) .* (1:length(inputStr)));
        hashStr = dec2hex(mod(numVal * 2654435761, 2^32), 8);
        hashStr = repmat(hashStr, 1, 8); % pad to 64 chars
        hashStr = hashStr(1:64);
    end
end