{ ... }:

{
	users.users.chase = {
		isNormalUser = true;
		extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
		initialPassword = "changeme";
	};
}
