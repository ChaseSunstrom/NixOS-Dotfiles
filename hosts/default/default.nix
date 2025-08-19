{ config, home-manager, lib, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
		../../modules/base.nix
		../../modules/packages.nix
		../../modules/users/chase.nix
		../../modules/services/hyprland.nix
		
		home-manager.nixosModules.home-manager
		({ ... }: {
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.chase = import ../../home/chase/default.nix;
		})
	];

	services.xserver.videoDrivers = [ "nvidia" ];

	hardware = {
		graphics.enable = true;
		nvidia = {
			modesetting.enable = true;
			nvidiaPersistenced = true;
			powerManagement.enable = true;
			powerManagement.finegrained = false;
			open = true;
			package = config.boot.kernelPackages.nvidiaPackages.stable;
		};
	};



	networking.hostName = "chase-laptop";
	time.timeZone = "America/Chicago";
	
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	boot.loader.efi.efiSysMountPoint = "/boot";
	services.logrotate.checkConfig = false;

	system.stateVersion = "25.05";
}
