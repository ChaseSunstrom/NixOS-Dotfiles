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
		xdg-utils
		wl-clipboard
		grim
		slurp
		brightnessctl
		pamixer
	];
	
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.fira-code
	];
}
