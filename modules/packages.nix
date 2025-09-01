{ pkgs, ... }:

{
	nixpkgs = {
		config = {
			allowUnfree = true;
		};
		# overlays = [ (import ../overlays/default.nix) ];
	};

	environment.systemPackages = with pkgs; [
		git
		neovim
		google-chrome
		kitty
		fish
		xdg-utils
		wl-clipboard
		grim
		slurp
		brightnessctl
		pamixer
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
	
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.fira-code
	];
}
