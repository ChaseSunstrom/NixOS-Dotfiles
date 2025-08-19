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
			command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
			user = "greeter";
		};	
	};
	
	environment.systemPackages = with pkgs; [
		hyprpaper
		hypridle
		hyprlock
		waybar
		wofi
	];
}
