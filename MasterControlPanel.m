function MasterControlPanel()
% MasterControlPanel
%
% Unified GUI for the retinal ganglion cell experimental pipeline.
% MATLAB 2016b compatible (uses figure/uicontrol, NOT uifigure).
%
% Tabs:
%   1. Full Field Flicker      - responsiveness check
%   2. Full Field Noise         - ON/OFF characterization (seeded Gaussian)
%   3. Checkerboard Noise       - spatial receptive field mapping
%   4. Jittering Circle          - RF-covering random walk stimulus
%
% PREREQUISITE: Stage-VSS server must be running in a separate MATLAB
%               instance before pressing any RUN button.
%
% CLAMPEX INTEGRATION: When 'Record with Clampex' is checked, each RUN
%   button will automatically start/stop a gap-free recording in Clampex
%   11.2 via SendKeys (Ctrl+Shift+1 toggle). Clampex must be open and
%   idle (not already recording) before clicking RUN.
%
% All stimulus scripts are from the WorkingStageCodes control set.
% Each script manages its own StageClient connection internally.

    % ---- Create main figure (classic figure, 2016b compatible) ----
    fig = figure('Name', 'Neitz Lab - Master Control Panel', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Position', [100 100 720 620], ...
        'Color', [0.15 0.15 0.18], ...
        'Resize', 'on');

    % ---- Status bar at the bottom ----
    statusLabel = uicontrol(fig, 'Style', 'text', ...
        'Position', [10 5 700 20], ...
        'String', 'Ready.', ...
        'ForegroundColor', [0.6 0.8 0.6], ...
        'BackgroundColor', [0.15 0.15 0.18], ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left');

    % ---- Title ----
    uicontrol(fig, 'Style', 'text', ...
        'Position', [10 580 700 30], ...
        'String', 'NEITZ LAB  -  MASTER CONTROL PANEL', ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'ForegroundColor', [0.9 0.9 0.95], ...
        'BackgroundColor', [0.15 0.15 0.18], ...
        'HorizontalAlignment', 'center');

    % ---- Clampex Recording Controls (persistent across all tabs) ----
    recordCheck = uicontrol(fig, 'Style', 'checkbox', ...
        'String', 'Record with Clampex', ...
        'Value', 0, ...
        'Position', [20 548 160 22], ...
        'ForegroundColor', [1 0.6 0.2], ...
        'BackgroundColor', [0.15 0.15 0.18], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');

    buildLabel(fig, 'Pre (s):', 190, 548);
    preDelayEdit = uicontrol(fig, 'Style', 'edit', ...
        'String', '2', ...
        'Position', [260 548 35 22]);

    buildLabel(fig, 'Post (s):', 305, 548);
    postDelayEdit = uicontrol(fig, 'Style', 'edit', ...
        'String', '2', ...
        'Position', [385 548 35 22]);

    buildLabel(fig, 'Trials:', 430, 548);
    trialsEdit = uicontrol(fig, 'Style', 'edit', ...
        'String', '1', ...
        'Position', [490 548 35 22]);

    buildLabel(fig, 'ITI (s):', 535, 548);
    itiEdit = uicontrol(fig, 'Style', 'edit', ...
        'String', '3', ...
        'Position', [605 548 35 22]);

    % ---- Tab Group ----
    tabGroup = uitabgroup(fig, 'Position', [0.01 0.05 0.97 0.84]);

    % =====================================================================
    %  TAB 1: Full Field Flicker
    % =====================================================================
    tab1 = uitab(tabGroup, 'Title', '1. Flicker', ...
        'BackgroundColor', [0.18 0.18 0.22]);

    buildSectionLabel(tab1, 'Full Field Flicker - Responsiveness Check', 10, 475);

    % Color mode
    buildLabel(tab1, 'Color Mode:', 20, 440);
    flickerModeDD = uicontrol(tab1, 'Style', 'popupmenu', ...
        'String', {'Greyscale (W/B)', 'S-Cone Isolating (R/G)'}, ...
        'Value', 1, ...
        'Position', [160 440 220 22]);

    buildLabel(tab1, 'Flicker Hz:', 20, 405);
    flickerHz1 = uicontrol(tab1, 'Style', 'edit', ...
        'String', '4', ...
        'Position', [160 405 80 22]);

    buildLabel(tab1, 'Stim Frames:', 20, 370);
    stimFrames1 = uicontrol(tab1, 'Style', 'edit', ...
        'String', '600', ...
        'Position', [160 370 80 22]);

    buildLabel(tab1, 'Refresh Rate:', 20, 335);
    refreshRate1 = uicontrol(tab1, 'Style', 'edit', ...
        'String', '60', ...
        'Position', [160 335 80 22]);

    uicontrol(tab1, 'Style', 'pushbutton', ...
        'String', 'RUN FLICKER', ...
        'Position', [20 275 200 40], ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'BackgroundColor', [0.2 0.6 0.3], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) runFlicker());

    % =====================================================================
    %  TAB 2: Full Field Noise (Seeded Gaussian)
    % =====================================================================
    tab2 = uitab(tabGroup, 'Title', '2. Full Field Noise', ...
        'BackgroundColor', [0.18 0.18 0.22]);

    buildSectionLabel(tab2, 'Full Field Gaussian Noise - ON/OFF Characterization', 10, 475);

    % Color mode
    buildLabel(tab2, 'Color Mode:', 20, 440);
    noiseModeDD = uicontrol(tab2, 'Style', 'popupmenu', ...
        'String', {'Greyscale', 'S-Cone Isolating'}, ...
        'Value', 1, ...
        'Position', [160 440 220 22]);

    buildLabel(tab2, 'Seed:', 20, 405);
    seed2 = uicontrol(tab2, 'Style', 'edit', ...
        'String', '2', ...
        'Position', [160 405 80 22]);

    buildLabel(tab2, 'Mu:', 20, 370);
    mu2 = uicontrol(tab2, 'Style', 'edit', ...
        'String', '0.5', ...
        'Position', [160 370 80 22]);

    buildLabel(tab2, 'Sigma:', 20, 335);
    sigma2 = uicontrol(tab2, 'Style', 'edit', ...
        'String', '0.3', ...
        'Position', [160 335 80 22]);

    buildLabel(tab2, 'Flicker Hz:', 20, 300);
    flickerHz2 = uicontrol(tab2, 'Style', 'edit', ...
        'String', '4', ...
        'Position', [160 300 80 22]);

    buildLabel(tab2, 'Stim Frames:', 20, 265);
    stimFrames2 = uicontrol(tab2, 'Style', 'edit', ...
        'String', '600', ...
        'Position', [160 265 80 22]);

    buildLabel(tab2, 'Refresh Rate:', 20, 230);
    refreshRate2 = uicontrol(tab2, 'Style', 'edit', ...
        'String', '60', ...
        'Position', [160 230 80 22]);

    uicontrol(tab2, 'Style', 'pushbutton', ...
        'String', 'RUN NOISE', ...
        'Position', [20 170 200 40], ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'BackgroundColor', [0.2 0.6 0.3], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) runNoise());

    % =====================================================================
    %  TAB 3: Checkerboard Noise
    % =====================================================================
    tab3 = uitab(tabGroup, 'Title', '3. Checkerboard', ...
        'BackgroundColor', [0.18 0.18 0.22]);

    buildSectionLabel(tab3, 'Checkerboard Gaussian Noise - Receptive Field Mapping', 10, 475);

    % Color mode
    buildLabel(tab3, 'Color Mode:', 20, 440);
    checkerModeDD = uicontrol(tab3, 'Style', 'popupmenu', ...
        'String', {'Greyscale', 'S-Cone Isolating'}, ...
        'Value', 1, ...
        'Position', [160 440 220 22]);

    buildLabel(tab3, 'Seed:', 20, 405);
    seed3 = uicontrol(tab3, 'Style', 'edit', ...
        'String', '2', ...
        'Position', [160 405 80 22]);

    buildLabel(tab3, 'Mu:', 20, 370);
    mu3 = uicontrol(tab3, 'Style', 'edit', ...
        'String', '0.5', ...
        'Position', [160 370 80 22]);

    buildLabel(tab3, 'Sigma:', 20, 335);
    sigma3 = uicontrol(tab3, 'Style', 'edit', ...
        'String', '0.3', ...
        'Position', [160 335 80 22]);

    buildLabel(tab3, 'Update Every N Frames:', 20, 300);
    updateN3 = uicontrol(tab3, 'Style', 'edit', ...
        'String', '1', ...
        'Position', [200 300 80 22]);

    buildLabel(tab3, 'Stim Frames:', 20, 265);
    stimFrames3 = uicontrol(tab3, 'Style', 'edit', ...
        'String', '600', ...
        'Position', [160 265 80 22]);

    buildLabel(tab3, 'Refresh Rate:', 20, 230);
    refreshRate3 = uicontrol(tab3, 'Style', 'edit', ...
        'String', '60', ...
        'Position', [160 230 80 22]);

    autoSave3 = uicontrol(tab3, 'Style', 'checkbox', ...
        'String', 'Auto-save noise for analysis', ...
        'Value', 1, ...
        'Position', [260 230 220 22], ...
        'ForegroundColor', [0.85 0.85 0.9], ...
        'BackgroundColor', [0.18 0.18 0.22], ...
        'FontSize', 10);

    uicontrol(tab3, 'Style', 'pushbutton', ...
        'String', 'RUN CHECKERBOARD', ...
        'Position', [20 170 220 40], ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'BackgroundColor', [0.2 0.6 0.3], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) runCheckerboard());

    % Save noise sequence button
    uicontrol(tab3, 'Style', 'pushbutton', ...
        'String', 'Save Noise for Analysis', ...
        'Position', [260 170 220 40], ...
        'FontSize', 10, ...
        'BackgroundColor', [0.3 0.3 0.5], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) saveNoiseSeq());

    % =====================================================================
    %  TAB 4: Jittering Circle Stimulus
    % =====================================================================
    tab4 = uitab(tabGroup, 'Title', '4. Jittering Circle', ...
        'BackgroundColor', [0.18 0.18 0.22]);

    buildSectionLabel(tab4, 'Jittering Circle - RF-Covering Random Walk', 10, 475);

    % ---- LEFT COLUMN: Analysis ----
    buildLabel(tab4, '-- ANALYSIS --', 20, 440);

    buildLabel(tab4, '.abf Files:', 20, 410);
    abfListBox = uicontrol(tab4, 'Style', 'listbox', ...
        'String', {}, ...
        'Position', [20 295 280 110], ...
        'Max', 100, 'Min', 0);

    uicontrol(tab4, 'Style', 'pushbutton', ...
        'String', 'Add .abf Files...', ...
        'Position', [20 260 135 28], ...
        'BackgroundColor', [0.3 0.3 0.5], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) addAbfFiles());

    uicontrol(tab4, 'Style', 'pushbutton', ...
        'String', 'Clear List', ...
        'Position', [165 260 135 28], ...
        'BackgroundColor', [0.5 0.3 0.3], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) clearAbfFiles());

    buildLabel(tab4, 'Seed (must match):', 20, 225);
    seed4 = uicontrol(tab4, 'Style', 'edit', ...
        'String', '2', ...
        'Position', [160 225 80 22]);

    buildLabel(tab4, 'Peak Height:', 20, 190);
    peakHeight4 = uicontrol(tab4, 'Style', 'edit', ...
        'String', '20.0', ...
        'Position', [160 190 80 22]);

    buildLabel(tab4, 'Stim Threshold:', 20, 155);
    stimThresh4 = uicontrol(tab4, 'Style', 'edit', ...
        'String', '1.0', ...
        'Position', [160 155 80 22]);

    uicontrol(tab4, 'Style', 'pushbutton', ...
        'String', 'ANALYZE RF', ...
        'Position', [20 105 140 40], ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'BackgroundColor', [0.2 0.4 0.7], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) analyzeRF());

    % RF result display
    rfResultLabel = uicontrol(tab4, 'Style', 'text', ...
        'Position', [20 70 280 30], ...
        'String', 'RF: not yet analyzed', ...
        'ForegroundColor', [0.7 0.7 0.7], ...
        'BackgroundColor', [0.18 0.18 0.22], ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left');

    % ---- RIGHT COLUMN: Stimulus Controls ----
    buildLabel(tab4, '-- STIMULUS --', 380, 440);

    buildLabel(tab4, 'Color Mode:', 380, 410);
    circleModeDD = uicontrol(tab4, 'Style', 'popupmenu', ...
        'String', {'Greyscale', 'S-Cone Isolating'}, ...
        'Value', 1, ...
        'Position', [510 410 160 22]);

    buildLabel(tab4, 'Circle Radius (px):', 380, 375);
    circleRadiusPx = uicontrol(tab4, 'Style', 'edit', ...
        'String', '150', ...
        'Position', [510 375 80 22]);

    buildLabel(tab4, 'Walk Speed (px/s):', 380, 340);
    walkSpeed = uicontrol(tab4, 'Style', 'edit', ...
        'String', '50', ...
        'Position', [510 340 80 22]);

    buildLabel(tab4, 'Duration (frames):', 380, 305);
    stimFrames4 = uicontrol(tab4, 'Style', 'edit', ...
        'String', '600', ...
        'Position', [510 305 80 22]);

    buildLabel(tab4, 'Refresh Rate:', 380, 270);
    refreshRate4 = uicontrol(tab4, 'Style', 'edit', ...
        'String', '60', ...
        'Position', [510 270 80 22]);

    % Simulation mode toggle
    simModeCheck = uicontrol(tab4, 'Style', 'checkbox', ...
        'String', 'Simulation Mode (use mock RF)', ...
        'Value', 0, ...
        'Position', [380 230 250 22], ...
        'ForegroundColor', [1 0.8 0.3], ...
        'BackgroundColor', [0.18 0.18 0.22], ...
        'FontSize', 10);

    uicontrol(tab4, 'Style', 'pushbutton', ...
        'String', 'RUN JITTERING CIRCLE', ...
        'Position', [380 165 200 50], ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'BackgroundColor', [0.2 0.6 0.3], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @(~,~) runJitteringCircle());

    % =====================================================================
    %  Store handles for data sharing between callbacks
    % =====================================================================
    guiData = struct();
    guiData.abfFiles = {};
    guiData.abfNames = {};
    guiData.rfCenterPx = [];
    guiData.rfRadiusPx = [];
    guiData.rfAnalyzed = false;
    setappdata(fig, 'guiData', guiData);

    % =====================================================================
    %  CALLBACK IMPLEMENTATIONS
    % =====================================================================

    % ---- Tab 1: Flicker ----
    function runFlicker()
        try
            hz = str2double(get(flickerHz1, 'String'));
            sf = str2double(get(stimFrames1, 'String'));
            rr = str2double(get(refreshRate1, 'String'));
            modeIdx = get(flickerModeDD, 'Value');

            if modeIdx == 1
                stimFn = @() AAGreyScaleFullFieldNoiseFinal2026(hz, sf, rr);
                stimName = 'greyscale flicker';
            else
                stimFn = @() AASConeIsoFullFieldNoiseStimFinal2026(hz, sf, rr);
                stimName = 'S-cone iso flicker';
            end

            runTrialLoop(stimFn, stimName);
        catch err
            setStatus(['ERROR: ' err.message]);
            fprintf(2, '[MCP] Flicker error:\n%s\n', getReport(err, 'extended'));
        end
    end

    % ---- Tab 2: Full Field Noise ----
    function runNoise()
        try
            sd = str2double(get(seed2, 'String'));
            m  = str2double(get(mu2, 'String'));
            sg = str2double(get(sigma2, 'String'));
            hz = str2double(get(flickerHz2, 'String'));
            sf = str2double(get(stimFrames2, 'String'));
            rr = str2double(get(refreshRate2, 'String'));
            modeIdx = get(noiseModeDD, 'Value');

            if modeIdx == 1
                stimFn = @() AASeededGaussianGreyScaleStimFinal2026(sd, m, sg, hz, sf, rr);
                stimName = 'greyscale full-field noise';
            else
                stimFn = @() AASeededGaussianSConeIsoStimFinal2026(sd, m, sg, hz, sf, rr);
                stimName = 'S-cone iso full-field noise';
            end

            runTrialLoop(stimFn, stimName);
        catch err
            setStatus(['ERROR: ' err.message]);
            fprintf(2, '[MCP] Noise error:\n%s\n', getReport(err, 'extended'));
        end
    end

    % ---- Tab 3: Checkerboard ----
    function runCheckerboard()
        try
            sd = str2double(get(seed3, 'String'));
            m  = str2double(get(mu3, 'String'));
            sg = str2double(get(sigma3, 'String'));
            un = str2double(get(updateN3, 'String'));
            sf = str2double(get(stimFrames3, 'String'));
            rr = str2double(get(refreshRate3, 'String'));
            modeIdx = get(checkerModeDD, 'Value');

            % Auto-save noise before stimulus (if enabled)
            if get(autoSave3, 'Value')
                setStatus('Auto-saving noise sequence...');
                saveCheckerboardNoiseForAnalysis(sd, m, sg, 40, 32, sf, un);
            end

            if modeIdx == 1
                stimFn = @() AASeededGaussianCheckerboardGreyScaleStimFinal(sd, m, sg, un, sf, rr);
                stimName = 'greyscale checkerboard';
            else
                stimFn = @() AASeededGaussianCheckerboardSConeIsoStimFinal(sd, m, sg, un, sf, rr);
                stimName = 'S-cone iso checkerboard';
            end

            runTrialLoop(stimFn, stimName);
        catch err
            setStatus(['ERROR: ' err.message]);
            fprintf(2, '[MCP] Checkerboard error:\n%s\n', getReport(err, 'extended'));
        end
    end

    function saveNoiseSeq()
        setStatus('Saving noise sequence...');
        drawnow;
        try
            sd = str2double(get(seed3, 'String'));
            m  = str2double(get(mu3, 'String'));
            sg = str2double(get(sigma3, 'String'));
            sf = str2double(get(stimFrames3, 'String'));
            un = str2double(get(updateN3, 'String'));
            saveCheckerboardNoiseForAnalysis(sd, m, sg, 40, 32, sf, un);
            setStatus(sprintf('Noise for seed=%d saved.', sd));
        catch err
            setStatus(['ERROR: ' err.message]);
            fprintf(2, '[MCP] Save noise error:\n%s\n', getReport(err, 'extended'));
        end
    end

    % ---- Tab 4: Analysis + Jittering Circle ----
    function addAbfFiles()
        [files, filePath] = uigetfile('*.abf', 'Select ABF Files', 'MultiSelect', 'on');
        if isequal(files, 0), return; end
        if ischar(files), files = {files}; end
        gd = getappdata(fig, 'guiData');
        for i = 1:numel(files)
            gd.abfFiles{end+1} = fullfile(filePath, files{i});
            gd.abfNames{end+1} = files{i};
        end
        setappdata(fig, 'guiData', gd);
        set(abfListBox, 'String', gd.abfNames);
        setStatus(sprintf('%d .abf file(s) loaded.', numel(gd.abfNames)));
    end

    function clearAbfFiles()
        gd = getappdata(fig, 'guiData');
        gd.abfFiles = {};
        gd.abfNames = {};
        setappdata(fig, 'guiData', gd);
        set(abfListBox, 'String', {});
        setStatus('ABF file list cleared.');
    end

    function analyzeRF()
        gd = getappdata(fig, 'guiData');
        if isempty(gd.abfFiles)
            setStatus('No .abf files loaded. Add files first.');
            return;
        end

        setStatus('Running Python analysis (CheckerboardSTA)...');
        drawnow;
        try
            sd  = str2double(get(seed4, 'String'));
            ph  = str2double(get(peakHeight4, 'String'));
            sth = str2double(get(stimThresh4, 'String'));

            [dataDir, ~, ~] = fileparts(gd.abfFiles{1});

            tmpScript = [tempname(), '.py'];
            fid = fopen(tmpScript, 'w');

            fprintf(fid, 'import sys\n');
            fprintf(fid, 'sys.path.insert(0, r''%s'')\n', pwd);
            fprintf(fid, 'from CheckerboardSTA import CheckerboardSTA\n');
            fprintf(fid, 'sta = CheckerboardSTA(\n');
            fprintf(fid, '    filepath=r''%s'',\n', dataDir);
            fprintf(fid, '    seed=%d,\n', sd);
            fprintf(fid, '    peak_height=%.2f,\n', ph);
            fprintf(fid, '    stim_threshold=%.2f,\n', sth);
            fprintf(fid, ')\n');

            abfParts = cell(1, numel(gd.abfNames));
            for k = 1:numel(gd.abfNames)
                abfParts{k} = ['''', gd.abfNames{k}, ''''];
            end
            abfNameStr = strjoin(abfParts, ', ');
            fprintf(fid, 'sta.load_and_analyze([%s])\n', abfNameStr);
            fprintf(fid, 'center_px, radius_px = sta.get_receptive_field_pixels()\n');

            rfMatPath = strrep(fullfile(dataDir, 'rf_params.mat'), '\', '\\');
            fprintf(fid, 'sta.export_rf_params(r''%s'')\n', rfMatPath);
            fprintf(fid, 'print(''RF_CENTER_X='' + str(round(center_px[0], 4)))\n');
            fprintf(fid, 'print(''RF_CENTER_Y='' + str(round(center_px[1], 4)))\n');
            fprintf(fid, 'print(''RF_RADIUS='' + str(round(radius_px, 4)))\n');
            fclose(fid);

            [exitCode, result] = system(sprintf('python "%s"', tmpScript));
            delete(tmpScript);

            if exitCode ~= 0
                setStatus(['Python error: ' result]);
                return;
            end

            cx = parseField(result, 'RF_CENTER_X');
            cy = parseField(result, 'RF_CENTER_Y');
            rr_val = parseField(result, 'RF_RADIUS');

            gd.rfCenterPx = [cx, cy];
            gd.rfRadiusPx = rr_val;
            gd.rfAnalyzed = true;
            setappdata(fig, 'guiData', gd);

            set(rfResultLabel, 'String', ...
                sprintf('RF: center=(%.0f, %.0f) px,  radius=%.0f px', cx, cy, rr_val));
            set(rfResultLabel, 'ForegroundColor', [0.3 1 0.4]);

            if str2double(get(circleRadiusPx, 'String')) == 150
                set(circleRadiusPx, 'String', num2str(round(rr_val * 1.5)));
            end

            setStatus(sprintf('Analysis complete: RF center=(%.0f,%.0f), radius=%.0f px', cx, cy, rr_val));
        catch err
            setStatus(['ERROR: ' err.message]);
            fprintf(2, '[MCP] Analysis error:\n%s\n', getReport(err, 'extended'));
        end
    end

    function runJitteringCircle()
        gd = getappdata(fig, 'guiData');
        useSim = get(simModeCheck, 'Value');

        if ~useSim && ~gd.rfAnalyzed
            setStatus('No RF data. Run analysis first or enable Simulation Mode.');
            return;
        end

        if useSim
            rfCx = 570; rfCy = 456; rfR = 80;
            setStatus('Simulation Mode: using mock RF at screen center.');
        else
            rfCx = gd.rfCenterPx(1);
            rfCy = gd.rfCenterPx(2);
            rfR  = gd.rfRadiusPx;
        end

        stimR = str2double(get(circleRadiusPx, 'String'));
        spd   = str2double(get(walkSpeed, 'String'));
        sf    = str2double(get(stimFrames4, 'String'));
        rr    = str2double(get(refreshRate4, 'String'));

        if stimR <= rfR
            setStatus(sprintf('ERROR: Circle radius (%.0f) must be > RF radius (%.0f)', stimR, rfR));
            return;
        end

        try
            modeItems = get(circleModeDD, 'String');
            mode = modeItems{get(circleModeDD, 'Value')};
            stimFn = @() AAJitteringCircleStimulusFinal([rfCx, rfCy], rfR, stimR, spd, sf, rr, mode);
            stimName = ['jittering circle (' mode ')'];

            runTrialLoop(stimFn, stimName);
        catch err
            setStatus(['ERROR: ' err.message]);
            fprintf(2, '[MCP] Jittering circle error:\n%s\n', getReport(err, 'extended'));
        end
    end

    % =====================================================================
    %  HELPER FUNCTIONS
    % =====================================================================
    function setStatus(msg)
        set(statusLabel, 'String', msg);
        drawnow;
    end

    function val = parseField(txt, fieldName)
        pattern = [fieldName, '=([0-9.\-]+)'];
        tokens = regexp(txt, pattern, 'tokens');
        if isempty(tokens)
            error('Could not parse %s from Python output:\n%s', fieldName, txt);
        end
        val = str2double(tokens{1}{1});
    end

    % ---- Clampex Recording Wrapper ----
    function runWithRecording(stimFn)
    % Wraps a stimulus function call with Clampex gap-free recording.
    % Uses WScript.Shell AppActivate to robustly target Clampex by
    % window title, then SendKeys Ctrl+Shift+1 to toggle recording.
    % Clampex must be open and idle (not already recording).
        preDelay  = str2double(get(preDelayEdit, 'String'));
        postDelay = str2double(get(postDelayEdit, 'String'));

        NET.addAssembly('System.Windows.Forms');

        % 1. Bring Clampex to foreground (robust: by window title)
        setStatus('Activating Clampex window...');
        drawnow;
        focusClampex();
        pause(0.3);

        % 2. Start gap-free recording (Ctrl+Shift+1)
        setStatus('Starting Clampex recording...');
        drawnow;
        System.Windows.Forms.SendKeys.SendWait('^+{1}');
        pause(0.1);

        % 3. Return focus to MATLAB
        focusMatlab();
        pause(0.2);

        % 4. Pre-stimulus delay
        setStatus(sprintf('Pre-stim delay (%.1f s)...', preDelay));
        drawnow;
        pause(preDelay);

        % 5. Run the stimulus
        setStatus('Running stimulus...');
        drawnow;
        stimFn();

        % 6. Post-stimulus delay
        setStatus(sprintf('Post-stim delay (%.1f s)...', postDelay));
        drawnow;
        pause(postDelay);

        % 7. Bring Clampex back to foreground
        setStatus('Stopping Clampex recording...');
        drawnow;
        focusClampex();
        pause(0.3);

        % 8. Stop recording (same toggle: Ctrl+Shift+1)
        System.Windows.Forms.SendKeys.SendWait('^+{1}');
        pause(0.1);

        % 9. Return focus to MATLAB
        focusMatlab();
        pause(0.2);

        setStatus('Recording saved by Clampex.');
        fprintf('[MCP] Clampex recording cycle complete.\n');
    end

    % ---- Trial Loop ----
    function runTrialLoop(stimFn, stimName)
    % Runs stimFn for the configured number of trials.
    % If recording is enabled, each trial is wrapped with Clampex.
        nTrials = max(1, round(str2double(get(trialsEdit, 'String'))));
        iti     = str2double(get(itiEdit, 'String'));
        useRec  = get(recordCheck, 'Value');

        for trial = 1:nTrials
            setStatus(sprintf('Trial %d/%d: %s...', trial, nTrials, stimName));
            fprintf('[MCP] === Trial %d/%d: %s ===\n', trial, nTrials, stimName);
            drawnow;

            if useRec
                runWithRecording(stimFn);
            else
                stimFn();
            end

            fprintf('[MCP] Trial %d/%d done.\n', trial, nTrials);

            % Inter-trial interval (skip after last trial)
            if trial < nTrials
                setStatus(sprintf('ITI (%.1f s) before trial %d...', iti, trial + 1));
                drawnow;
                pause(iti);
            end
        end

        setStatus(sprintf('All %d trials of %s complete.', nTrials, stimName));
        fprintf('[MCP] All %d trials complete.\n', nTrials);
    end

    % ---- Focus Helpers (robust window targeting) ----
    function focusClampex()
    % Activates the Clampex window by searching for its title.
    % Uses WScript.Shell COM object for robust window targeting.
        try
            shell = actxserver('WScript.Shell');
            found = shell.AppActivate('Clampex');
            if ~found
                % Fallback: try pCLAMP title variant
                found = shell.AppActivate('pCLAMP');
            end
            if ~found
                warning('[MCP] Could not find Clampex window. Is it open?');
            end
            delete(shell);
        catch
            % Last-resort fallback: Alt+Tab
            NET.addAssembly('System.Windows.Forms');
            System.Windows.Forms.SendKeys.SendWait('%{TAB}');
        end
    end

    function focusMatlab()
    % Returns focus to the MATLAB window.
        try
            shell = actxserver('WScript.Shell');
            shell.AppActivate('MATLAB');
            delete(shell);
        catch
            NET.addAssembly('System.Windows.Forms');
            System.Windows.Forms.SendKeys.SendWait('%{TAB}');
        end
    end
end

% =========================================================================
%  UI BUILDER HELPERS (local functions at file scope)
% =========================================================================
function lbl = buildLabel(parent, text, x, y)
    lbl = uicontrol(parent, 'Style', 'text', ...
        'Position', [x y 200 20], ...
        'String', text, ...
        'ForegroundColor', [0.85 0.85 0.9], ...
        'BackgroundColor', [0.18 0.18 0.22], ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left');
end

function lbl = buildSectionLabel(parent, text, x, y)
    lbl = uicontrol(parent, 'Style', 'text', ...
        'Position', [x y 660 22], ...
        'String', text, ...
        'ForegroundColor', [0.5 0.8 1], ...
        'BackgroundColor', [0.18 0.18 0.22], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left');
end
