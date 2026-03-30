function AAJitteringCircleStimulusFinal(rfCenter, rfRadius, circleRadius, walkSpeed, stimFrames, refreshRate, colorMode)
% AAJitteringCircleStimulusFinal
%
% Stage-VSS stimulus: A single circle performing a random walk (jitter)
% around a target Receptive Field (RF) center.
%
% Parameters:
%   rfCenter      - [x, y] in pixels
%   rfRadius      - radius in pixels (used for scaling/reference)
%   circleRadius  - stimulus circle radius in pixels
%   walkSpeed     - speed of jitter in pixels/second
%   stimFrames    - duration in frames
%   refreshRate   - display refresh rate (Hz)
%   colorMode     - 'Greyscale' or 'S-Cone Isolating'

    if nargin < 1 || isempty(rfCenter),     rfCenter = [570, 456]; end
    if nargin < 2 || isempty(rfRadius),     rfRadius = 80;         end
    if nargin < 3 || isempty(circleRadius), circleRadius = 150;    end
    if nargin < 4 || isempty(walkSpeed),    walkSpeed = 50;        end
    if nargin < 5 || isempty(stimFrames),   stimFrames = 600;      end
    if nargin < 6 || isempty(refreshRate),  refreshRate = 60;      end
    if nargin < 7 || isempty(colorMode),    colorMode = 'Greyscale'; end

    % ---- HARD REQUIREMENT: client/server pipeline ----
    client = stage.core.network.StageClient();
    client.connect();
    canvasSize = client.getCanvasSize();
    fprintf('[AAJitteringCircle] Connected. Canvas: %d x %d\n', canvasSize(1), canvasSize(2));

    import stage.core.*;
    import stage.builtin.stimuli.*;
    import stage.builtin.controllers.*;

    W = canvasSize(1);
    H = canvasSize(2);

    % ---- Parameters ----
    preFrames  = 5;
    postFrames = 5;
    totalFrames = preFrames + stimFrames + postFrames;
    totalDuration = totalFrames / refreshRate;

    % ---- Precompute Jitter (Random Walk) ----
    % We want the circle to jitter. 
    % Step size per frame = walkSpeed / refreshRate * randn()
    % To keep it centered 'on average', we use a small spring constant (Ornstein-Uhlenbeck)
    % so it doesn't drift off screen during long runs.
    
    posX = zeros(totalFrames, 1);
    posY = zeros(totalFrames, 1);
    
    curX = rfCenter(1);
    curY = rfCenter(2);
    
    % Step standard deviation
    stepSigma = walkSpeed / refreshRate;
    % Spring constant (0.01 means it pulls back 1% of the distance to center each frame)
    k = 0.02; 
    
    % Seed the walk for reproducibility (use same seed logic as other scripts if needed)
    stream = RandStream('mt19937ar', 'Seed', 2); 
    
    for f = 1:totalFrames
        if f <= preFrames || f > (preFrames + stimFrames)
            posX(f) = rfCenter(1);
            posY(f) = rfCenter(2);
        else
            % Update position with random walk + spring back to center
            dx = stepSigma * randn(stream);
            dy = stepSigma * randn(stream);
            
            curX = curX + dx - k * (curX - rfCenter(1));
            curY = curY + dy - k * (curY - rfCenter(2));
            
            posX(f) = curX;
            posY(f) = curY;
        end
    end

    % ---- Precompute Right Bar Colors ----
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

    % ---- Determine Color ----
    if strcmpi(colorMode, 'S-Cone Isolating')
        % S-Cone: R=1, G=0, B=0 (following logic from other S-cone scripts)
        circColor = [1 0 0];
    else
        % Greyscale: White
        circColor = [1 1 1];
    end

    % ---- Debug prints ----
    fprintf('\n--- Stage Jittering Circle Stimulus ---\n');
    fprintf('RF Center: (%.1f, %.1f), Radius: %.1f px\n', rfCenter(1), rfCenter(2), rfRadius);
    fprintf('Circle Radius: %.1f px, Walk Speed: %.1f px/s\n', circleRadius, walkSpeed);
    fprintf('Stim Frames: %d, Total Duration: %.2f s\n', stimFrames, totalDuration);
    fprintf('Color Mode: %s\n', colorMode);

    % ---- Stimuli ----
    % Background
    background = Rectangle();
    background.size = [W, H];
    background.position = [W/2, H/2];
    background.color = [0 0 0]; % Black background

    % The Jittering Circle
    circle = Ellipse(); 
    circle.radiusX = circleRadius;
    circle.radiusY = circleRadius;
    circle.color   = circColor;
    circle.position = rfCenter;

    % Sync Bar
    rightBar = Rectangle();
    rightBar.size     = [W/8, H];
    rightBar.position = [W - W/16, H/2];
    rightBar.color    = [0 0 0];

    % ---- Controllers ----
    posCtrl = PropertyController(circle, 'position', ...
        @(s) [posX(min(max(floor(s.time * refreshRate) + 1, 1), totalFrames)), ...
              posY(min(max(floor(s.time * refreshRate) + 1, 1), totalFrames))]);

    rightBarCtrl = PropertyController(rightBar, 'color', ...
        @(s) rightBarColors(min(max(floor(s.time * refreshRate) + 1, 1), totalFrames), :));

    % ---- Presentation ----
    presentation = Presentation(totalDuration);
    presentation.addStimulus(background);
    presentation.addStimulus(circle);
    presentation.addStimulus(rightBar);
    
    presentation.addController(posCtrl);
    presentation.addController(rightBarCtrl);

    player = stage.builtin.players.RealtimePlayer(presentation);
    fprintf('[AAJitteringCircle] Playing...\n');
    client.play(player);
    fprintf('[AAJitteringCircle] Done.\n');
end
