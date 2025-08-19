{ config, pkgs, ... }:

{
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	i18n.defaultLocale = "en_US.UTF-8";
	console.keyMap = "us";

	networking.networkmanager.enable = true;

	services.pipewire = {
		enable = true;
		alsa.enable = true;
		pulse.enable = true;
		jack.enable = true;
	};
	
	services.libinput.enable = true;
	
	services.xserver.enable = false;

	environment.sessionVariables.NIXOS_OZONE_WL = "1";

}
