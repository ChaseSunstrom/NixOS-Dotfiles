{ config, lib, pkgs, pkgsUnstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/packages.nix
    ../../modules/users/chase.nix
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

  xdg.portal = {
  	enable = true;
	extraPortals = lib.mkForce [
		pkgsUnstable.xdg-desktop-portal-hyprland
		pkgs.xdg-desktop-portal-gtk
	];
  };

		  programs.hyprland = {
			enable = true;
			package = pkgsUnstable.hyprland;
		  };

  services.greetd = {
    enable = true;

    # Optional: autologin straight into Hyprland
    # autologin = {
    #   enable = true;
    #   user = "chase";
    #   command = "Hyprland";
    # };

    settings = {
      default_session = {
        # Run the TUI greeter on the login TTY
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd Hyprland";
        user = "greeter";
      };
    };
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Location for weather etc.
  services.geoclue2.enable = true;

  # Keyring-backed secrets (for KeyringStorage in the config)
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Network module expects NM
  networking.networkmanager.enable = true;

  # Locker PAM (match what you actually run)
  security.pam.services.swaylock = {};
  # or: security.pam.services.hyprlock = {};  # This is fine to keep here; it’s just an option path,
  # it doesn’t require importing HM in this file:

  networking.hostName = "chase-desktop";
  time.timeZone = "America/Chicago";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  services.logrotate.checkConfig = false;

  system.stateVersion = "25.05";
}

