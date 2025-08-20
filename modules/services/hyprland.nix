{ pkgs, ... }:

{
	programs.hyprland.enable = true;
	
	xdg.portal = {
		enable = true;
		extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-hyprland ];
	};
	
	services.greetd = {
		enable = true;
		settings.default_session = {
			# Use a graphical greeter (ReGreet) inside cage for a prettier login
			command = "${pkgs.cage}/bin/cage -s -- ${pkgs.greetd.regreet}/bin/regreet";
			user = "greeter";
		};	
	};
	
	environment.systemPackages = with pkgs; [
		hypridle
		hyprlock
		waybar
		wofi
		swww
		waypaper
		python3Packages.pywal
		swaynotificationcenter
		cage
	];
}
