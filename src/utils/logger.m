%% ========================================================================
% FILE: logger.m
% DESCRIPTION: Simple logging utility. Writes to console and log file.
%
% USAGE:
%   log = logger('results/logs/run.log');
%   log.info('Starting...');
%   log.warn('Something odd');
%   log.error('Failed!');
%   log.close();
%% ========================================================================

classdef logger < handle
    properties
        fid
        filepath
        startTime
    end

    methods
        function obj = logger(filepath)
            obj.filepath = filepath;
            obj.fid = fopen(filepath, 'w');
            obj.startTime = tic;
            if obj.fid == -1
                warning('Cannot open log file: %s. Logging to console only.', filepath);
            end
            obj.info('Logger initialized.');
        end

        function info(obj, msg)
            str = sprintf('[INFO  %s] %s', datestr(now,'HH:MM:SS'), msg);
            fprintf('%s\n', str);
            if obj.fid > 0; fprintf(obj.fid, '%s\n', str); end
        end

        function warn(obj, msg)
            str = sprintf('[WARN  %s] %s', datestr(now,'HH:MM:SS'), msg);
            fprintf(2, '%s\n', str);
            if obj.fid > 0; fprintf(obj.fid, '%s\n', str); end
        end

        function error(obj, msg)
            str = sprintf('[ERROR %s] %s', datestr(now,'HH:MM:SS'), msg);
            fprintf(2, '%s\n', str);
            if obj.fid > 0; fprintf(obj.fid, '%s\n', str); end
        end

        function elapsed = getElapsed(obj)
            elapsed = toc(obj.startTime);
        end

        function close(obj)
            obj.info(sprintf('Total elapsed: %.1f seconds.', obj.getElapsed()));
            if obj.fid > 0; fclose(obj.fid); end
        end
    end
end