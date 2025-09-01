{
  description = "NixOS Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    dotsHyprland = {
      url = "github:ChaseSunstrom/dots-hyprland";
      flake = false;
    };
  };


	outputs = { self, nixpkgs, home-manager, nixpkgsUnstable, dotsHyprland, ... }:
	let
	  system = "x86_64-linux";
	  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
	  pkgsUnstable = import nixpkgsUnstable { inherit system; config.allowUnfree = true; };
	in {
	  nixosConfigurations = {
	    default = nixpkgs.lib.nixosSystem {
	      inherit system;

	      # pass inputs to your modules
	      specialArgs = { inherit dotsHyprland; inherit pkgsUnstable; };

	      modules = [
		./hosts/default

		home-manager.nixosModules.home-manager
		{
		  home-manager.useGlobalPkgs = true;
		  home-manager.useUserPackages = true;
		  home-manager.users.chase = { pkgs, ...}: {
		  	imports = [
				./home/chase
				./modules/services	
			];
		  };
		  home-manager.extraSpecialArgs = { dotsHyprland = dotsHyprland; pkgsUnstable = pkgsUnstable; };

		  # (either specialArgs above OR this line is fine; you don't need both)
		  # _module.args.dots-hyprland = dots-hyprland;
		}
	      ];
	    };
	  };
	};

}

