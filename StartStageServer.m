function StartStageServer()
% StartStageServer
%
% Automatically launches the Stage-VSS server on the SECOND monitor 
% (usually the LightCrafter projector) in FULLSCREEN at its native 
% 1140x912 resolution, completely bypassing the manual Configuration GUI 
% that often gets stuck between screens.
%
% Usage: Run this in your Server MATLAB instance before opening the Master Control Panel.

    import stage.core.*;
    import stage.core.network.*;

    fprintf('Looking for available monitors...\n');
    monitors = Monitor.availableMonitors();
    
    for i = 1:numel(monitors)
        res = monitors{i}.resolution;
        fprintf('Monitor %d: %d x %d\n', i, res(1), res(2));
    end

    % Determine the target monitor (default to Monitor 2 if it exists, else Monitor 1)
    targetMonitorIndex = 2;
    if numel(monitors) < 2
        fprintf('WARNING: Only 1 monitor detected. Using Monitor 1.\n');
        targetMonitorIndex = 1;
    end

    % Define native LightCrafter resolution
    width = 1140;
    height = 912;
    isFullscreen = true;

    fprintf('Starting Stage Window on Monitor %d (%dx%d)...\n', targetMonitorIndex, width, height);
    
    try
        % Create the window directly (bypassing the GUI)
        window = Window([width, height], isFullscreen, monitors{targetMonitorIndex});
        
        % Start the server with this window
        server = StageServer(window);
        
        fprintf('Stage Server is now running! Waiting for client connections...\n');
        fprintf('(Press CTRL+C in this command window to stop the server)\n');
        
        server.start();
    catch err
        fprintf(2, 'Failed to start Stage Server:\n%s\n', err.message);
        
        % Try to clean up if the window was created but server failed to bind
        if exist('window', 'var') && isvalid(window)
            window.close();
        end
    end
end
