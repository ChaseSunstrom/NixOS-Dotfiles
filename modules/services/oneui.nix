{ config, pkgs, ... }:

let
  oneuiIcons = pkgs.stdenvNoCC.mkDerivation {
    pname = "oneui4-icons";
    version = "git-55eada4"; # or whatever commit you want
src = pkgs.fetchFromGitHub {
  owner = "end-4";
  repo = "OneUI4-Icons";
  rev = "main";
  hash = "sha256-VWgITEJQFbPqIbiGDfDeD0R74y9tCKEfjO/M/tcO94M=";
};
    installPhase = ''
    runHook preInstall
    install -dm755 $out/share/icons
    for d in OneUI OneUI-dark OneUI-light; do
      cp -dr --no-preserve=mode "$d" "$out/share/icons/$d"
    done
    # remove any dangling symlinks so fixupPhase passes
    find "$out/share/icons" -xtype l -print -delete
    runHook postInstall
    '';
  };
in {
  home.packages = [ oneuiIcons ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "OneUI";
      package = oneuiIcons;
    };
  };

  home.sessionVariables = {
    # use config attrs that exist in HM scope
    QT_ICON_THEME = "OneUI";
    XDG_DATA_DIRS =
      "${config.home.profileDirectory}/share:/run/current-system/sw/share:${config.home.homeDirectory}/.local/share";
  };

}

