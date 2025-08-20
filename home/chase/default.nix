
{ config, pkgs, ... }:

{
	home.username = "chase";
	home.homeDirectory = "/home/chase";
	home.stateVersion = "25.05";

	programs.git.enable = true;
	programs.kitty.enable = true;
	programs.wofi.enable = true;
	programs.waybar.enable = true;

	# Developer-friendly packages and CLI tools
	home.packages = with pkgs; [
		# CLI quality of life
		bat
		ripgrep
		fd
		eza
		btop
		jq
		yazi
		ncdu
		fzf
		# Dev runtimes & tooling
		nodejs_22
		bun
		python3
		python3Packages.pip
		rustup
		go
		# Git helpers
		git-absorb
		pre-commit
		# Theming helpers
		wallust
	];

	imports = [
		./hyprland.nix
		./waybar.nix
	];
}
