function AASeededGaussianGreyScaleStimFinal2026(seed, mu, sigma, flickerHz, stimFrames, refreshRate)
% AASeededGaussianGreyScaleStimFinal2026
%
% Stage-VSS client/server, full-field Image stimulus.
% Full-field: seeded Gaussian noise -> R=v, G=v, B=v (greyscale)
% Implemented as a 1x1 Image with imageMatrix controller.
%
% Right-side bar (1/8 width) flickers BLUE <-> BLACK every frame.
%
% All callbacks use pure anonymous functions with precomputed lookup
% tables for Stage serialization compatibility.

    % ---- Parameters with defaults ----
    if nargin < 1 || isempty(seed),        seed = 2;          end
    if nargin < 2 || isempty(mu),           mu = 0.5;         end
    if nargin < 3 || isempty(sigma),        sigma = 0.3;      end
    if nargin < 4 || isempty(flickerHz),    flickerHz = 4;     end
    if nargin < 5 || isempty(stimFrames),   stimFrames = 600;  end
    if nargin < 6 || isempty(refreshRate),  refreshRate = 60;  end

    % ---- HARD REQUIREMENT: client/server pipeline ----
    client = stage.core.network.StageClient();
    client.connect();
    canvasSize = client.getCanvasSize();
    fprintf('[AASeededGaussianGreyScaleStimFinal2026] Connected. Canvas: %d x %d\n', canvasSize(1), canvasSize(2));

    import stage.core.*;
    import stage.builtin.stimuli.*;
    import stage.builtin.controllers.*;

    % ---- Display geometry ----
    W = canvasSize(1);
    H = canvasSize(2);

    % ---- Parameters ----
    checksX = 1;
    checksY = 1;
    preFrames  = 5;
    postFrames = 5;

    updateEveryNFrames = max(1, round(refreshRate / (2 * flickerHz)));

    totalFrames   = preFrames + stimFrames + postFrames;
    totalDuration = totalFrames / refreshRate;
    nUpdates = ceil(stimFrames / updateEveryNFrames);

    % ---- Precompute noise ----
    stream = RandStream('mt19937ar', 'Seed', seed);
    noiseVals = mu + sigma .* randn(stream, checksY, checksX, nUpdates);
    noiseVals = min(max(noiseVals, 0), 1);

    % ---- Precompute imageMatrix for EVERY frame (cell array) ----
    blackRGB = zeros(checksY, checksX, 3, 'uint8');
    allFrameImages = cell(totalFrames, 1);

    for f = 1:totalFrames
        if f <= preFrames || f > (preFrames + stimFrames)
            allFrameImages{f} = blackRGB;
        else
            stimF = f - preFrames;
            updateIdx = min(max(floor((stimF - 1) / updateEveryNFrames) + 1, 1), nUpdates);
            v = noiseVals(:, :, updateIdx);
            g = uint8(round(v * 255));
            img = zeros(checksY, checksX, 3, 'uint8');
            img(:,:,1) = g;
            img(:,:,2) = g;
            img(:,:,3) = g;
            allFrameImages{f} = img;
        end
    end

    % ---- Precompute right bar colors ----
    rightBarColors = zeros(totalFrames, 3);
    for f = 1:totalFrames
        if f <= preFrames || f > (preFrames + stimFrames)
            rightBarColors(f,:) = [0 0 0];
        else
            stimF = f - preFrames;
            if mod(stimF, 2) == 1
                rightBarColors(f,:) = [0 0 1];
            else
                rightBarColors(f,:) = [0 0 0];
            end
        end
    end

    % ---- Debug prints ----
    fprintf('\n--- Stage Full-Field Gaussian GRAYSCALE Stimulus ---\n');
    fprintf('Canvas: %d x %d, refreshRate: %d Hz\n', W, H, refreshRate);
    fprintf('stimFrames: %d, totalDuration: %.2f s\n', stimFrames, totalDuration);
    fprintf('updateEveryNFrames: %d, nUpdates: %d\n', updateEveryNFrames, nUpdates);
    fprintf('seed: %d, mu: %.3f, sigma: %.3f\n', seed, mu, sigma);

    % ---- Stimuli ----
    checkerboard = Image(blackRGB);
    checkerboard.position = [W/2, H/2];
    checkerboard.size = [W, H];
    checkerboard.setMinFunction(GL.NEAREST);
    checkerboard.setMagFunction(GL.NEAREST);

    rightBar = Rectangle();
    rightBar.size     = [W/8, H];
    rightBar.position = [W - W/16, H/2];
    rightBar.color    = [0 0 0];

    % ---- Controllers (pure anonymous functions - NO subfunctions) ----
    imageCtrl = PropertyController(checkerboard, 'imageMatrix', ...
        @(s) allFrameImages{min(max(floor(s.time * refreshRate) + 1, 1), totalFrames)});

    rightBarCtrl = PropertyController(rightBar, 'color', ...
        @(s) rightBarColors(min(max(floor(s.time * refreshRate) + 1, 1), totalFrames), :));

    % ---- Presentation + player ----
    presentation = Presentation(totalDuration);
    presentation.addStimulus(checkerboard);
    presentation.addStimulus(rightBar);
    presentation.addController(imageCtrl);
    presentation.addController(rightBarCtrl);

    player = stage.builtin.players.RealtimePlayer(presentation);
    fprintf('[AASeededGaussianGreyScaleStimFinal2026] Playing (%.1f sec)...\n', totalDuration);
    client.play(player);
    fprintf('[AASeededGaussianGreyScaleStimFinal2026] Done.\n');
end
