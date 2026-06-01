function saveFlickerForAnalysis(flickerHz, stimFrames, refreshRate, colorMode, savePath)
% saveFlickerForAnalysis
%
% Exports the per-frame brightness values for the full-field flicker
% stimulus as a CSV file. One row per frame, columns: frame, time_s, R, G, B.
%
% Usage:
%   saveFlickerForAnalysis(4, 600, 60, 'greyscale')
%   saveFlickerForAnalysis(4, 600, 60, 'scone')

    if nargin < 1 || isempty(flickerHz),   flickerHz = 4;           end
    if nargin < 2 || isempty(stimFrames),   stimFrames = 600;        end
    if nargin < 3 || isempty(refreshRate),  refreshRate = 60;        end
    if nargin < 4 || isempty(colorMode),    colorMode = 'greyscale'; end
    if nargin < 5 || isempty(savePath),     savePath = '';           end

    preFrames  = 5;
    postFrames = 5;
    totalFrames = preFrames + stimFrames + postFrames;
    framesPerHalfCycle = max(1, round(refreshRate / (2 * flickerHz)));

    % ---- Precompute per-frame RGB (same logic as stimulus script) ----
    R = zeros(totalFrames, 1);
    G = zeros(totalFrames, 1);
    B = zeros(totalFrames, 1);

    for f = 1:totalFrames
        if f <= preFrames || f > (preFrames + stimFrames)
            % Pre/post: black
            R(f) = 0; G(f) = 0; B(f) = 0;
        else
            stimF = f - preFrames;
            halfCycleIdx = floor((stimF - 1) / framesPerHalfCycle);
            if strcmpi(colorMode, 'scone')
                % S-Cone: red <-> green
                if mod(halfCycleIdx, 2) == 0
                    R(f) = 255; G(f) = 0; B(f) = 0;
                else
                    R(f) = 0; G(f) = 255; B(f) = 0;
                end
            else
                % Greyscale: black <-> white
                if mod(halfCycleIdx, 2) == 0
                    R(f) = 0; G(f) = 0; B(f) = 0;
                else
                    R(f) = 255; G(f) = 255; B(f) = 255;
                end
            end
        end
    end

    % ---- Build output path ----
    if isempty(savePath)
        savePath = fullfile(pwd, 'data', sprintf('flicker_%s_%dHz.csv', colorMode, flickerHz));
    end

    [outDir, ~, ~] = fileparts(savePath);
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    % ---- Write CSV ----
    fid = fopen(savePath, 'w');
    fprintf(fid, 'frame,time_s,R,G,B\n');
    for f = 1:totalFrames
        fprintf(fid, '%d,%.6f,%d,%d,%d\n', f, (f-1)/refreshRate, R(f), G(f), B(f));
    end
    fclose(fid);

    fprintf('Flicker brightness saved to:\n  %s\n', savePath);
    fprintf('  %d frames, %s mode, %d Hz\n', totalFrames, colorMode, flickerHz);
end
