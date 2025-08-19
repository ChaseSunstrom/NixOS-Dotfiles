{

	description = "NixOS Hyprland";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		home-manager.url = "github:nix-community/home-manager/release-25.05";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = { self, nixpkgs, home-manager, ... }:

	let 
		system = "x86_64-linux";
		lib = nixpkgs.lib;
	in {
		nixosConfigurations.default = lib.nixosSystem {
			inherit system;
			specialArgs = { inherit nixpkgs home-manager; };
			modules = [ ./hosts/default/default.nix ];
		};
	};

}
