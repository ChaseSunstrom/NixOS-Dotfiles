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
		exec-once = hyprpaper
	'';

	xdg.configFile."hypr/hyprpaper.conf".text = ''
		preload = /usr/share/backgrounds/nixos/nix-wallpaper-simple-dark.png
		wallpaper = ,/usr/share/backgrounds/nixos/nix-wallpaper-simple-dark.png
	'';
}
