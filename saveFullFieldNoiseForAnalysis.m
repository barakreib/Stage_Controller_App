function saveFullFieldNoiseForAnalysis(seed, mu, sigma, flickerHz, stimFrames, refreshRate, colorMode, savePath)
% saveFullFieldNoiseForAnalysis
%
% Exports the per-frame brightness values for the full-field Gaussian noise
% stimulus as a CSV file. One row per frame, columns: frame, time_s, R, G, B.
%
% Uses the EXACT same RandStream('mt19937ar', 'Seed', seed) as the
% stimulus scripts, ensuring perfect reproducibility for analysis.
%
% Usage:
%   saveFullFieldNoiseForAnalysis(2, 0.5, 0.3, 4, 600, 60, 'greyscale')
%   saveFullFieldNoiseForAnalysis(2, 0.5, 0.3, 4, 600, 60, 'scone')

    if nargin < 1 || isempty(seed),        seed = 2;                end
    if nargin < 2 || isempty(mu),           mu = 0.5;               end
    if nargin < 3 || isempty(sigma),        sigma = 0.3;            end
    if nargin < 4 || isempty(flickerHz),    flickerHz = 4;           end
    if nargin < 5 || isempty(stimFrames),   stimFrames = 600;        end
    if nargin < 6 || isempty(refreshRate),  refreshRate = 60;        end
    if nargin < 7 || isempty(colorMode),    colorMode = 'greyscale'; end
    if nargin < 8 || isempty(savePath),     savePath = '';           end

    preFrames  = 5;
    postFrames = 5;
    totalFrames = preFrames + stimFrames + postFrames;
    updateEveryNFrames = max(1, round(refreshRate / (2 * flickerHz)));
    nUpdates = ceil(stimFrames / updateEveryNFrames);

    % ---- Generate noise (same RandStream as stimulus script) ----
    stream = RandStream('mt19937ar', 'Seed', seed);
    noiseVals = mu + sigma .* randn(stream, 1, 1, nUpdates);
    noiseVals = min(max(noiseVals, 0), 1);

    % ---- Precompute per-frame RGB ----
    R = zeros(totalFrames, 1);
    G = zeros(totalFrames, 1);
    B = zeros(totalFrames, 1);

    for f = 1:totalFrames
        if f <= preFrames || f > (preFrames + stimFrames)
            R(f) = 0; G(f) = 0; B(f) = 0;
        else
            stimF = f - preFrames;
            updateIdx = min(max(floor((stimF - 1) / updateEveryNFrames) + 1, 1), nUpdates);
            v = noiseVals(1, 1, updateIdx);
            if strcmpi(colorMode, 'scone')
                R(f) = round(v * 255);
                G(f) = round((1 - v) * 255);
                B(f) = 0;
            else
                g = round(v * 255);
                R(f) = g; G(f) = g; B(f) = g;
            end
        end
    end

    % ---- Build output path ----
    if isempty(savePath)
        savePath = fullfile(pwd, 'data', sprintf('fullfield_noise_%s_seed%d.csv', colorMode, seed));
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

    fprintf('Full-field noise brightness saved to:\n  %s\n', savePath);
    fprintf('  %d frames, %s mode, seed=%d, mu=%.2f, sigma=%.2f\n', ...
        totalFrames, colorMode, seed, mu, sigma);
end
