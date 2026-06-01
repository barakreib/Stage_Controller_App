% Experimenter5000 - Fixed version with proper Clampex toggle pairing
%
% CRITICAL FIXES (April 2026):
%   1. Added STOP recording toggle - previously only START was sent
%   2. Removed redundant pause(stim_dur+1) - stimulus is already blocking
%   3. Added robust Clampex window targeting on every trial (not just trial 1)
%   4. Added timestamped logging for all key events
%
% NOTE: Consider using MasterControlPanel.m instead for full GUI support.
%
% PREREQUISITE: Clampex must be open and IDLE (not recording) before running.

pre_stim  = 2;     % seconds of baseline before stimulus
post_stim = 2;     % seconds of baseline after stimulus
iti       = 3;     % inter-trial interval (seconds)
nTrials   = 5;

% Load .NET assembly once at startup (not per-trial)
NET.addAssembly('System.Windows.Forms');

fprintf('\n========================================\n');
fprintf('Experimenter5000 - Starting %d trials\n', nTrials);
fprintf('Time: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
fprintf('Pre: %.1f s, Post: %.1f s, ITI: %.1f s\n', pre_stim, post_stim, iti);
fprintf('========================================\n\n');

for ind = 1:nTrials
    fprintf('[Trial %d/%d] START at %s\n', ind, nTrials, datestr(now, 'HH:MM:SS.FFF'));

    % --- Activate Clampex window (robust: by title, every trial) ---
    try
        shell = actxserver('WScript.Shell');
        found = shell.AppActivate('Clampex');
        if ~found, found = shell.AppActivate('pCLAMP'); end
        delete(shell);
        if ~found
            warning('[Exp5000] Could not find Clampex window! Is it open?');
        end
    catch
        % Last-resort fallback
        System.Windows.Forms.SendKeys.SendWait('%{TAB}');
    end
    pause(0.3);

    % --- START Clampex Recording (Ctrl+Shift+1) ---
    System.Windows.Forms.SendKeys.SendWait('^+{1}');
    fprintf('[Trial %d/%d] Clampex recording STARTED at %s\n', ind, nTrials, datestr(now, 'HH:MM:SS.FFF'));
    pause(0.1);

    % --- Return focus to MATLAB ---
    try
        shell = actxserver('WScript.Shell');
        shell.AppActivate('MATLAB');
        delete(shell);
    catch
    end
    pause(0.2);

    % --- Pre-stimulus baseline ---
    fprintf('[Trial %d/%d] Pre-stimulus delay (%.1f s)...\n', ind, nTrials, pre_stim);
    pause(pre_stim);

    % --- Run stimulus (BLOCKING - client.play() waits for completion) ---
    fprintf('[Trial %d/%d] Stimulus START at %s\n', ind, nTrials, datestr(now, 'HH:MM:SS.FFF'));
    AAGreyScaleFullFieldNoiseFinal2026();
%   AASConeIsoFullFieldNoiseStimFinal2026();
%   AASeededGaussianCheckerboardSConeIsoStimFinal();
%   AASeededGaussianCheckerboardGreyScaleStimFinal();
    fprintf('[Trial %d/%d] Stimulus DONE at %s\n', ind, nTrials, datestr(now, 'HH:MM:SS.FFF'));

    % --- Post-stimulus baseline ---
    % NOTE: No extra pause needed! client.play() already blocked for the
    % full stimulus duration. We only wait for post_stim baseline.
    fprintf('[Trial %d/%d] Post-stimulus delay (%.1f s)...\n', ind, nTrials, post_stim);
    pause(post_stim);

    % --- Activate Clampex window again for STOP ---
    try
        shell = actxserver('WScript.Shell');
        found = shell.AppActivate('Clampex');
        if ~found, found = shell.AppActivate('pCLAMP'); end
        delete(shell);
        if ~found
            warning('[Exp5000] Could not refocus Clampex to STOP recording!');
        end
    catch
        System.Windows.Forms.SendKeys.SendWait('%{TAB}');
    end
    pause(0.3);

    % --- STOP Clampex Recording (Ctrl+Shift+1) ---
    System.Windows.Forms.SendKeys.SendWait('^+{1}');
    fprintf('[Trial %d/%d] Clampex recording STOPPED at %s\n', ind, nTrials, datestr(now, 'HH:MM:SS.FFF'));
    pause(0.1);

    % --- Return focus to MATLAB ---
    try
        shell = actxserver('WScript.Shell');
        shell.AppActivate('MATLAB');
        delete(shell);
    catch
    end

    fprintf('[Trial %d/%d] COMPLETE at %s\n\n', ind, nTrials, datestr(now, 'HH:MM:SS.FFF'));

    % --- Inter-trial interval (skip after last trial) ---
    if ind < nTrials
        fprintf('[Trial %d/%d] ITI (%.1f s) before next trial...\n', ind, nTrials, iti);
        pause(iti);
    end
end

fprintf('========================================\n');
fprintf('Experiment COMPLETE at %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
fprintf('All %d trials done.\n', nTrials);
fprintf('========================================\n');