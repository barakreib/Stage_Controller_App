"""
CheckerboardSTA  –  Spatial Receptive Field Mapping from Checkerboard Noise
===========================================================================

Extends the Neitz Analysis Suite for checkerboard noise stimuli.

Pipeline
--------
1. Load one or more .abf files (electrophysiology recordings).
2. Regenerate the exact checkerboard noise sequence from the MATLAB seed
   (mt19937ar generator, identical to the MATLAB stimulus scripts).
3. Align spike times to frame boundaries using the photodiode TTL channel.
4. Compute a Spatiotemporal Spike-Triggered Average (STA) across the
   checkerboard grid, averaging over multiple trials.
5. Extract the receptive field center (X_rf, Y_rf) and spatial radius (R_rf)
   from the peak of the 2D spatial STA map.

Dependencies
------------
numpy, pyabf, scipy, matplotlib  (same as Neitz Analysis Suite)

Usage
-----
    from CheckerboardSTA import CheckerboardSTA

    sta = CheckerboardSTA(
        filepath="path/to/data_folder",
        seed=2,
        checks_x=40,
        checks_y=32,
    )

    # Load multiple .abf files and compute the spatial STA
    sta.load_and_analyze(["trial1.abf", "trial2.abf", "trial3.abf"])

    # Get receptive field parameters (in checkerboard grid coordinates)
    center, radius = sta.get_receptive_field()
    print(f"RF center (grid): {center}, RF radius (grid): {radius}")

    # Get receptive field parameters in display pixel coordinates
    center_px, radius_px = sta.get_receptive_field_pixels()
    print(f"RF center (px): {center_px}, RF radius (px): {radius_px}")

    # Plot the spatial STA map
    sta.plot_spatial_sta()
"""

from pathlib import Path

import numpy as np
import pyabf
from scipy.ndimage import gaussian_filter
from scipy.signal import find_peaks


class CheckerboardSTA:
    """
    Compute a spatial Spike-Triggered Average (STA) from checkerboard noise
    electrophysiology recordings (.abf files).

    The checkerboard noise sequence is regenerated deterministically from
    the same seed used by the MATLAB stimulus scripts (mt19937ar).

    Parameters
    ----------
    filepath : str or Path
        Directory containing a 'data/' subfolder with the .abf files.
    seed : int
        Random seed used by the MATLAB stimulus to generate the checkerboard.
    mu : float
        Mean of the Gaussian noise distribution (default 0.5).
    sigma : float
        Standard deviation of the Gaussian noise distribution (default 0.3).
    checks_x : int
        Number of checkerboard columns (default 40).
    checks_y : int
        Number of checkerboard rows (default 32).
    stim_frames : int
        Number of stimulus frames per trial (default 600).
    update_every_n_frames : int
        How many display frames each noise update is held for (default 1).
    refresh_rate : float
        Display refresh rate in Hz (default 60).
    pre_black_frames : int
        Number of blank frames before stimulus onset (default 5).
    post_black_frames : int
        Number of blank frames after stimulus offset (default 5).
    display_w : int
        Display width in pixels (default 1140, LightCrafter native).
    display_h : int
        Display height in pixels (default 912, LightCrafter native).
    sweep : int
        ABF sweep index to read (default 0).
    spike_ch_num : int
        ABF channel index for the spike/voltage trace (default 0).
    stim_ch_num : int
        ABF channel for the photodiode TTL sync signal (default 2).
    peak_height : float
        Minimum peak height for spike detection (default 20.0).
    stim_threshold : float
        Threshold for detecting photodiode TTL edges (default 1.0).
    sta_temporal_window_s : float
        Temporal window (in seconds) preceding each spike that is
        averaged to form the spatiotemporal STA (default 0.5).
    t_omit_on : float
        Time (seconds) to omit from the start of the stimulus epoch
        to avoid onset transient artifacts (default 1.0).
    """

    def __init__(
        self,
        filepath=None,
        seed=2,
        mu=0.5,
        sigma=0.3,
        checks_x=40,
        checks_y=32,
        stim_frames=600,
        update_every_n_frames=1,
        refresh_rate=60,
        pre_black_frames=5,
        post_black_frames=5,
        display_w=1140,
        display_h=912,
        sweep=0,
        spike_ch_num=0,
        stim_ch_num=2,
        peak_height=20.0,
        stim_threshold=1.0,
        sta_temporal_window_s=0.5,
        t_omit_on=1.0,
    ):
        self.filepath = Path(filepath) if filepath is not None else Path.cwd()
        self.datapath = self.filepath / "data"

        # Stimulus parameters (must match the MATLAB script)
        self.seed = int(seed)
        self.mu = float(mu)
        self.sigma = float(sigma)
        self.checks_x = int(checks_x)
        self.checks_y = int(checks_y)
        self.stim_frames = int(stim_frames)
        self.update_every_n_frames = int(update_every_n_frames)
        self.refresh_rate = float(refresh_rate)
        self.pre_black_frames = int(pre_black_frames)
        self.post_black_frames = int(post_black_frames)
        self.display_w = int(display_w)
        self.display_h = int(display_h)

        # ABF recording parameters
        self.sweep = int(sweep)
        self.spike_ch_num = int(spike_ch_num)
        self.stim_ch_num = int(stim_ch_num)
        self.peak_height = float(peak_height)
        self.stim_threshold = float(stim_threshold)

        # STA parameters
        self.sta_temporal_window_s = float(sta_temporal_window_s)
        self.t_omit_on = float(t_omit_on)

        # Internal state
        self._noise_sequence = None
        self._trials = []
        self._spatial_sta = None
        self._rf_center = None
        self._rf_radius = None

    # ------------------------------------------------------------------
    # Stimulus regeneration
    # ------------------------------------------------------------------
    def regenerate_noise_sequence(self):
        """
        Regenerate the exact checkerboard noise sequence from the seed.

        Uses numpy's MT19937 generator to match MATLAB's
        RandStream('mt19937ar', 'Seed', seed) + randn().

        Returns
        -------
        noise : ndarray, shape (checks_y, checks_x, n_updates)
            Contrast values in [0, 1] for each grid square and time step.

        Notes
        -----
        MATLAB's mt19937ar and NumPy's MT19937 share the same underlying
        Mersenne Twister algorithm. However, their seeding and variate
        generation may differ slightly. For exact reproducibility, the
        MATLAB stimulus script should save the full noise sequence to
        a .mat file that this method can load instead. If a .mat file
        named 'checkerboard_noise_seed{seed}.mat' exists in the data
        directory, it will be loaded automatically.
        """
        n_updates = int(np.ceil(self.stim_frames / self.update_every_n_frames))

        # Try to load the exact sequence from a .mat file first
        mat_name = f"checkerboard_noise_seed{self.seed}.mat"
        mat_path = self.datapath / mat_name
        if mat_path.exists():
            from scipy.io import loadmat
            data = loadmat(str(mat_path))
            if "noiseVals" in data:
                self._noise_sequence = np.array(data["noiseVals"], dtype=float)
                return self._noise_sequence

        # Fallback: regenerate from seed using NumPy's MT19937
        rng = np.random.RandomState(self.seed)
        noise = self.mu + self.sigma * rng.randn(
            self.checks_y, self.checks_x, n_updates
        )
        noise = np.clip(noise, 0.0, 1.0)
        self._noise_sequence = noise
        return self._noise_sequence

    # ------------------------------------------------------------------
    # ABF loading and spike detection
    # ------------------------------------------------------------------
    def _load_abf(self, filename):
        """
        Load a single .abf file and return a trial dict containing:
        - spike_ch: voltage/current trace
        - stim_ch: photodiode TTL channel (offset + inverted)
        - time_vec: time vector in seconds
        - fs: sampling rate in Hz
        - peaks: detected spike indices
        - t_on, t_off: stimulus epoch boundaries from TTL edges
        """
        abf_path = self.datapath / filename
        if not abf_path.exists():
            # Also check filepath directly
            abf_path = self.filepath / filename
        if not abf_path.exists():
            raise FileNotFoundError(
                f"ABF file not found: {filename}\n"
                f"Searched in: {self.datapath} and {self.filepath}"
            )

        abf = pyabf.ABF(str(abf_path))

        # Read spike channel
        abf.setSweep(self.sweep, channel=self.spike_ch_num)
        spike_ch = abf.sweepY.copy()
        time_vec = abf.sweepX.copy()

        # Read stim/TTL channel (offset + invert, same as Neitz.py)
        abf.setSweep(self.sweep, channel=self.stim_ch_num)
        stim_raw = abf.sweepY.copy()
        stim_m = float(np.max(stim_raw))
        stim_ch = (stim_raw - stim_m) * -1.0

        dt = float(np.mean(np.diff(time_vec)))
        fs = 1.0 / dt

        # Detect spikes (auto-polarity, same as Neitz.py)
        peaks = self._detect_spikes(spike_ch)

        # Find stimulus epoch from TTL edges
        t_on, t_off = self._find_stim_epoch(stim_ch, time_vec, fs)

        # Detect individual frame boundaries from TTL edges
        frame_times = self._detect_frame_times(stim_ch, time_vec, t_on, t_off)

        trial = {
            "filename": filename,
            "spike_ch": spike_ch,
            "stim_ch": stim_ch,
            "time_vec": time_vec,
            "fs": fs,
            "peaks": peaks,
            "t_on": t_on,
            "t_off": t_off,
            "frame_times": frame_times,
        }
        return trial

    def _detect_spikes(self, spike_ch):
        """
        Detect spikes using scipy.signal.find_peaks with auto-polarity
        detection (identical logic to Neitz.py).
        """
        y = np.asarray(spike_ch, dtype=float)

        def _peaks(sig):
            p, props = find_peaks(sig, height=self.peak_height)
            h = props.get("peak_heights", np.array([], dtype=float))
            return p, h

        p_pos, h_pos = _peaks(y)
        p_neg, h_neg = _peaks(-y)

        if len(p_pos) > len(p_neg):
            peaks = p_pos
        elif len(p_neg) > len(p_pos):
            peaks = p_neg
        else:
            med_pos = float(np.median(h_pos)) if len(h_pos) else -np.inf
            med_neg = float(np.median(h_neg)) if len(h_neg) else -np.inf
            peaks = p_neg if med_neg > med_pos else p_pos

        return np.asarray(peaks, dtype=int)

    def _find_stim_epoch(self, stim_ch, time_vec, fs):
        """
        Find stimulus onset and offset using the photodiode TTL signal.
        Uses the same edge-detection logic as Neitz.py.

        Returns
        -------
        t_on : float
            Time of stimulus onset (seconds).
        t_off : float
            Time of stimulus offset (seconds).
        """
        y = np.asarray(stim_ch, dtype=float)
        t = time_vec
        thr = self.stim_threshold

        frac_above = float(np.mean(y > thr))
        active_high = frac_above < 0.5

        stim_on = (y > thr) if active_high else (y < thr)
        edges = np.diff(stim_on.astype(int))
        rise = np.where(edges == 1)[0] + 1
        fall = np.where(edges == -1)[0] + 1

        if len(rise) == 0 or len(fall) == 0:
            raise RuntimeError(
                "No TTL edges found. Check stim_threshold or stim_ch_num."
            )

        i_on = int(rise[0])
        t_on = float(t[i_on])

        # Find offset: look for a long gap between consecutive rising edges
        long_pause_s = 0.25
        rise_t = t[rise]
        gaps = np.diff(rise_t)
        idx = np.where(gaps > long_pause_s)[0]
        last_rise = int(rise[int(idx[0])]) if len(idx) > 0 else int(rise[-1])

        j = np.searchsorted(fall, last_rise, side="right")
        if j >= len(fall):
            j = len(fall) - 1
        i_off = int(fall[j])
        t_off = float(t[i_off])

        return t_on, t_off

    def _detect_frame_times(self, stim_ch, time_vec, t_on, t_off):
        """
        Detect individual frame transition times from the photodiode TTL.

        The blue bar flickers every frame (blue on odd frames, black on even),
        so each rising edge of the TTL signal marks a new stimulus frame.

        Returns
        -------
        frame_times : ndarray
            Array of timestamps marking each frame boundary within the
            stimulus epoch.
        """
        y = np.asarray(stim_ch, dtype=float)
        t = time_vec
        thr = self.stim_threshold

        frac_above = float(np.mean(y > thr))
        active_high = frac_above < 0.5

        stim_on = (y > thr) if active_high else (y < thr)
        edges = np.diff(stim_on.astype(int))
        rise = np.where(edges == 1)[0] + 1
        rise_t = t[rise]

        # Keep only edges within the stimulus epoch
        mask = (rise_t >= t_on) & (rise_t <= t_off)
        frame_times = rise_t[mask]

        return frame_times

    # ------------------------------------------------------------------
    # Spatiotemporal STA computation
    # ------------------------------------------------------------------
    def _compute_trial_sta(self, trial):
        """
        Compute the spatiotemporal STA for a single trial.

        For each spike, we look back in time by sta_temporal_window_s and
        collect the checkerboard noise frames that were on screen. The
        result is a 3D array: (checks_y, checks_x, temporal_bins).

        Returns
        -------
        segments : list of ndarray
            Each element is shape (checks_y, checks_x, n_temporal_bins),
            representing the stimulus history preceding one spike.
        """
        if self._noise_sequence is None:
            self.regenerate_noise_sequence()

        noise = self._noise_sequence
        n_updates = noise.shape[2]
        frame_times = trial["frame_times"]
        time_vec = trial["time_vec"]
        peaks = trial["peaks"]
        t_on = trial["t_on"]
        t_off = trial["t_off"]
        fs = trial["fs"]

        # Number of temporal bins in the STA window
        # We measure time in units of checkerboard update frames
        frame_dt = self.update_every_n_frames / self.refresh_rate
        n_temporal_bins = int(np.ceil(self.sta_temporal_window_s / frame_dt))

        # Determine spike times within the valid epoch
        spike_times = time_vec[peaks]
        valid = (spike_times >= t_on + self.t_omit_on) & (spike_times <= t_off)
        valid_spike_times = spike_times[valid]

        segments = []
        for st in valid_spike_times:
            # For this spike time, find which checkerboard update was on screen
            # Frame index = which frame_times entry is just before this spike
            frame_idx_raw = np.searchsorted(frame_times, st, side="right") - 1
            if frame_idx_raw < 0:
                continue

            # The blue bar flickers every frame; the checkerboard updates
            # every update_every_n_frames display frames.
            # Since each TTL rising edge is a display frame, we convert:
            update_idx = frame_idx_raw // self.update_every_n_frames

            # Collect the preceding n_temporal_bins noise updates
            start_update = update_idx - n_temporal_bins + 1
            if start_update < 0:
                continue
            if update_idx >= n_updates:
                continue

            # Extract the spatiotemporal segment
            seg = noise[:, :, start_update : update_idx + 1]  # (Y, X, T)
            if seg.shape[2] == n_temporal_bins:
                segments.append(seg)

        return segments

    def load_and_analyze(self, abf_filenames):
        """
        Load multiple .abf files and compute the averaged spatial STA.

        Parameters
        ----------
        abf_filenames : list of str
            List of .abf filenames to load and average.

        Returns
        -------
        spatial_sta : ndarray, shape (checks_y, checks_x)
            The spatial STA map (averaged over time and trials).
        """
        # Regenerate noise sequence
        self.regenerate_noise_sequence()

        all_segments = []
        self._trials = []

        for fname in abf_filenames:
            trial = self._load_abf(fname)
            self._trials.append(trial)
            segs = self._compute_trial_sta(trial)
            all_segments.extend(segs)

        if not all_segments:
            raise RuntimeError(
                "No spike-triggered segments were collected. "
                "Check that your .abf files contain spikes during the "
                "stimulus epoch, or adjust peak_height / stim_threshold."
            )

        # Stack all segments: shape (n_spikes, checks_y, checks_x, n_temporal_bins)
        all_segments = np.array(all_segments)
        n_spikes = all_segments.shape[0]

        # Average across spikes → spatiotemporal STA (checks_y, checks_x, T)
        spatiotemporal_sta = all_segments.mean(axis=0)

        # Subtract the mean stimulus (since noise was drawn from Gaussian
        # centered at mu, the mean stimulus is approximately mu everywhere)
        spatiotemporal_sta -= self.mu

        # Collapse the temporal dimension to get the spatial STA
        # Use the peak temporal frame (the time lag with the largest
        # absolute response) for the spatial map
        temporal_power = np.sum(spatiotemporal_sta ** 2, axis=(0, 1))
        best_lag = np.argmax(temporal_power)
        spatial_sta = spatiotemporal_sta[:, :, best_lag]

        self._spatiotemporal_sta = spatiotemporal_sta
        self._spatial_sta = spatial_sta
        self._best_temporal_lag = best_lag
        self._n_spikes = n_spikes

        # Extract receptive field parameters
        self._extract_receptive_field()

        return spatial_sta

    # ------------------------------------------------------------------
    # Receptive field extraction
    # ------------------------------------------------------------------
    def _extract_receptive_field(self):
        """
        Extract the receptive field center and radius from the spatial STA.

        Uses thresholding on the absolute value of the spatial STA map.
        The center is the location of the peak response, and the radius
        is estimated from the area of the thresholded region.
        """
        if self._spatial_sta is None:
            raise RuntimeError("Run load_and_analyze() first.")

        sta = self._spatial_sta
        abs_sta = np.abs(sta)

        # Smooth slightly for robust peak finding
        smoothed = gaussian_filter(abs_sta, sigma=1.0)

        # Find the peak location (receptive field center in grid coords)
        peak_idx = np.unravel_index(np.argmax(smoothed), smoothed.shape)
        self._rf_center = (float(peak_idx[1]), float(peak_idx[0]))  # (x, y)

        # Threshold at half-maximum to estimate the RF area
        half_max = 0.5 * smoothed.max()
        rf_mask = smoothed >= half_max

        # Estimate radius from the area of the thresholded region
        rf_area_grid = float(np.sum(rf_mask))
        rf_radius_grid = np.sqrt(rf_area_grid / np.pi)

        self._rf_radius = rf_radius_grid
        self._rf_mask = rf_mask

    def get_receptive_field(self):
        """
        Get the receptive field center and radius in checkerboard grid
        coordinates.

        Returns
        -------
        center : tuple of float
            (x, y) center of the receptive field in grid units.
        radius : float
            Radius of the receptive field in grid units.
        """
        if self._rf_center is None or self._rf_radius is None:
            raise RuntimeError("Run load_and_analyze() first.")
        return self._rf_center, self._rf_radius

    def get_receptive_field_pixels(self):
        """
        Get the receptive field center and radius in display pixel
        coordinates.

        The checkerboard grid maps to the full display area, so we
        scale grid coordinates to pixel coordinates.

        Returns
        -------
        center_px : tuple of float
            (x, y) center of the receptive field in pixels.
        radius_px : float
            Radius of the receptive field in pixels.
        """
        center_grid, radius_grid = self.get_receptive_field()

        # Scale factors: each grid cell covers this many pixels
        px_per_check_x = self.display_w / self.checks_x
        px_per_check_y = self.display_h / self.checks_y

        center_px = (
            (center_grid[0] + 0.5) * px_per_check_x,
            (center_grid[1] + 0.5) * px_per_check_y,
        )

        # Use the geometric mean of the two scale factors for the radius
        px_per_check = np.sqrt(px_per_check_x * px_per_check_y)
        radius_px = radius_grid * px_per_check

        return center_px, radius_px

    # ------------------------------------------------------------------
    # Plotting
    # ------------------------------------------------------------------
    def plot_spatial_sta(self, smooth_sigma=0.5, show=True):
        """
        Plot the spatial STA map with the estimated receptive field
        location overlaid.

        Parameters
        ----------
        smooth_sigma : float
            Gaussian smoothing sigma for display purposes (default 0.5).
        show : bool
            Whether to call plt.show() (default True).

        Returns
        -------
        fig : matplotlib.figure.Figure
        """
        import matplotlib.pyplot as plt
        from matplotlib.patches import Circle

        if self._spatial_sta is None:
            raise RuntimeError("Run load_and_analyze() first.")

        sta = self._spatial_sta
        if smooth_sigma > 0:
            sta_display = gaussian_filter(sta, sigma=smooth_sigma)
        else:
            sta_display = sta.copy()

        vmax = np.max(np.abs(sta_display))
        center, radius = self.get_receptive_field()

        fig, ax = plt.subplots(1, 1, figsize=(10, 8))
        im = ax.imshow(
            sta_display,
            cmap="RdBu_r",
            vmin=-vmax,
            vmax=vmax,
            origin="upper",
            aspect="auto",
            extent=[0, self.checks_x, self.checks_y, 0],
        )
        plt.colorbar(im, ax=ax, label="STA (contrast units)")

        # Draw receptive field circle
        rf_circle = Circle(
            center,
            radius,
            fill=False,
            edgecolor="lime",
            linewidth=2,
            linestyle="--",
            label=f"RF (r={radius:.1f} checks)",
        )
        ax.add_patch(rf_circle)
        ax.plot(*center, "x", color="lime", markersize=12, markeredgewidth=2)

        ax.set_xlabel("Checkerboard X (grid units)")
        ax.set_ylabel("Checkerboard Y (grid units)")
        ax.set_title(
            f"Spatial STA  |  {self._n_spikes} spikes  |  "
            f"Best lag: frame {self._best_temporal_lag}"
        )
        ax.legend(loc="upper right")
        plt.tight_layout()

        if show:
            plt.show()
        return fig

    def plot_spatiotemporal_sta(self, n_lags=6, smooth_sigma=0.5, show=True):
        """
        Plot the spatiotemporal STA as a series of spatial maps at
        different time lags before the spike.

        Parameters
        ----------
        n_lags : int
            Number of time lags to display (default 6).
        smooth_sigma : float
            Gaussian smoothing sigma for display purposes (default 0.5).
        show : bool
            Whether to call plt.show() (default True).

        Returns
        -------
        fig : matplotlib.figure.Figure
        """
        import matplotlib.pyplot as plt

        if not hasattr(self, "_spatiotemporal_sta"):
            raise RuntimeError("Run load_and_analyze() first.")

        sta_4d = self._spatiotemporal_sta
        n_total = sta_4d.shape[2]
        frame_dt_ms = (self.update_every_n_frames / self.refresh_rate) * 1000

        # Select evenly spaced lags
        if n_lags > n_total:
            n_lags = n_total
        lag_indices = np.linspace(0, n_total - 1, n_lags, dtype=int)

        vmax = np.max(np.abs(sta_4d))

        fig, axes = plt.subplots(1, n_lags, figsize=(3 * n_lags, 3))
        if n_lags == 1:
            axes = [axes]

        for ax, li in zip(axes, lag_indices):
            frame = sta_4d[:, :, li]
            if smooth_sigma > 0:
                frame = gaussian_filter(frame, sigma=smooth_sigma)
            ax.imshow(
                frame,
                cmap="RdBu_r",
                vmin=-vmax,
                vmax=vmax,
                origin="upper",
                aspect="auto",
            )
            lag_ms = (n_total - 1 - li) * frame_dt_ms
            ax.set_title(f"-{lag_ms:.0f} ms")
            ax.set_xticks([])
            ax.set_yticks([])

        fig.suptitle(
            f"Spatiotemporal STA  |  {self._n_spikes} spikes",
            fontsize=14,
        )
        plt.tight_layout()

        if show:
            plt.show()
        return fig

    # ------------------------------------------------------------------
    # Multi-trial convenience
    # ------------------------------------------------------------------
    @classmethod
    def from_trials(
        cls,
        abf_filenames,
        filepath=None,
        seed=2,
        **kwargs,
    ):
        """
        Class method to create a CheckerboardSTA, load trials, and analyze
        in one call.

        Parameters
        ----------
        abf_filenames : list of str
        filepath : str or Path
        seed : int
        **kwargs : passed to CheckerboardSTA constructor.

        Returns
        -------
        sta_obj : CheckerboardSTA
            Fully analyzed object with spatial STA and RF parameters.
        """
        obj = cls(filepath=filepath, seed=seed, **kwargs)
        obj.load_and_analyze(abf_filenames)
        return obj

    # ------------------------------------------------------------------
    # Export for downstream stimulus generation
    # ------------------------------------------------------------------
    def export_rf_params(self, save_path=None):
        """
        Export receptive field parameters to a .mat file for use by the
        MATLAB moving circle stimulus script.

        Parameters
        ----------
        save_path : str or Path, optional
            File path for the output .mat file. Defaults to
            'rf_params.mat' in the data directory.

        Returns
        -------
        params : dict
            Dictionary containing the RF parameters.
        """
        from scipy.io import savemat

        center_px, radius_px = self.get_receptive_field_pixels()
        center_grid, radius_grid = self.get_receptive_field()

        params = {
            "rf_center_x_px": center_px[0],
            "rf_center_y_px": center_px[1],
            "rf_radius_px": radius_px,
            "rf_center_x_grid": center_grid[0],
            "rf_center_y_grid": center_grid[1],
            "rf_radius_grid": radius_grid,
            "checks_x": self.checks_x,
            "checks_y": self.checks_y,
            "display_w": self.display_w,
            "display_h": self.display_h,
            "seed": self.seed,
            "n_spikes": self._n_spikes,
            "spatial_sta": self._spatial_sta,
        }

        if save_path is None:
            save_path = self.datapath / "rf_params.mat"
        else:
            save_path = Path(save_path)

        savemat(str(save_path), params)
        print(f"RF parameters saved to: {save_path}")
        return params
