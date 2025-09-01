{ config, pkgs, ... }:

{
	programs.zsh.enable = true;

	users.users.chase = {
		isNormalUser = true;
		shell = pkgs.zsh;
		extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
		initialPassword = "changeme";
	};
}
