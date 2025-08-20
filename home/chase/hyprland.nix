{ pkgs, ... }:

{
	xdg.configFile."hypr/hyprland.conf".text = ''
		monitor=,preferred,auto,auto
		$mod = SUPER
		bind = $mod, t, exec, kitty
		bind = $mod, r, exec, wofi --show drun
		bind = $mod, Q, killactive,
		bind = $mod SHIFT, Q, exit,
		bind = $mod, SPACE, togglefloating
		# Start wallpaper daemon and notification center
		exec-once = swww-daemon
		exec-once = swaync

		# Keybind to launch wallpaper picker
		bind = $mod, W, exec, waypaper

		# Reload Waybar after theme changes
		bind = $mod SHIFT, R, exec, pkill -SIGUSR2 waybar || true
	'';

	# Wallust + Waybar styling hooks
	xdg.configFile."waybar/style.css" = {
		source = "${pkgs.writeText "waybar-style.css" ''
			@import url("${pkgs.wallust}/share/wallust/templates/colors-waybar.css");
			* { font-family: "FiraCode Nerd Font", sans-serif; font-size: 12pt; }
			window#waybar { background: alpha(@background, 0.6); color: @foreground; }
			#workspaces button.focused { background: @color1; color: @background; }
			#clock, #battery, #pulseaudio, #network { padding: 0 10px; }
		''}";
	};

	# Script that runs after Waypaper changes the wallpaper to regenerate colors
	# and reload relevant components
	xdg.configFile."wallust/hooks/update_theme.sh" = {
		executable = true;
		text = ''
			#!/usr/bin/env bash
			set -euo pipefail
			IMAGE_PATH="$1"
			# Generate palette
			${pkgs.wallust}/bin/wallust run "$IMAGE_PATH" -s dark -o ~/.cache/wallust
			# Export environment for new shells
			if [ -f "$HOME/.cache/wallust/sequences" ]; then
				cat "$HOME/.cache/wallust/sequences" > "$HOME/.wallust_seqs"
			fi
			# Reload waybar and swaync to pick up CSS/theme
			pkill -SIGUSR2 waybar || true
			${pkgs.swaynotificationcenter}/bin/swaync-client --reload || true
		'';
	};

	# Waypaper configuration to use swww backend and trigger the hook
	xdg.configFile."waypaper/config.ini".text = ''
		[Default]
		backend = swww
		fill = fill
		post_command = ${pkgs.bash}/bin/bash ~/.config/wallust/hooks/update_theme.sh {wallpaper}
		# Directory to scan for images by default
		folders = ~/Pictures/Wallpapers
	'';
}
