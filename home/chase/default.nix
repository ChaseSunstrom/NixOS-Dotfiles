
{ config, pkgs, ... }:

{
	home.username = "chase";
	home.homeDirectory = "/home/chase";
	home.stateVersion = "25.05";

	programs.git.enable = true;

	imports = [
		./hyprland.nix
		./waybar.nix
	];
}
