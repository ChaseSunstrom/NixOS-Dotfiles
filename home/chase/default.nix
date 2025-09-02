{ config, pkgs, pkgsUnstable, lib, dotsHyprland, ... }:

let
  cfgRoot = dotsHyprland;
  cfgDot  = "${cfgRoot}/.config";
  wanted = [ "default.target" "base.target" "graphical-session.target" "hyprland-session.target" ];
  haveCfg = builtins.pathExists cfgDot;
  skipTop = [ "systemd" "fontconfig" ];

  # Quickshell Python venv (env4 expects this and points to it with ILLOGICAL_IMPULSE_VIRTUAL_ENV)
  venvPath = "${config.home.homeDirectory}/.local/state/quickshell/.venv";

  collect = rel:
  	let
		here = cfgDot + (if rel == "" then "" else "/${rel}");
		attrs = if haveCfg && builtins.pathExists here then builtins.readDir here else { };
		names = builtins.attrNames attrs;
	in
		builtins.concatMap (n:
			if (rel == "" && lib.elem n skipTop) then []
			else
				let
					nextRel = if rel == "" then n else "${rel}/${n}";
					kind = attrs.${n};
				in
					if kind == "directory" then collect nextRel ++ [ nextRel]
					else [ nextRel ]
				) names;

  toNullAttrs = paths: builtins.listToAttrs (map (p: {
  	name = p;
	value = lib.mkForce { enable = false; };
  }) paths);
  
  disableSet = toNullAttrs (collect "");

  wallpaperFile = "${config.home.homeDirectory}/.cache/wallpaper/current";
  makeWritableDir = name: ''
    if [ -L "$HOME/.config/${name}" ]; then rm -f "$HOME/.config/${name}"; fi
    if [ ! -d "$HOME/.config/${name}" ]; then
      mkdir -p "$HOME/.config/${name}"
      cp -r --no-preserve=mode,ownership "${cfgDot}/${name}"/. "$HOME/.config/${name}"/ 2>/dev/null || true
    fi
  '';

  # Script that applies colors from current wallpaper: matugen -> env4 wrapper -> reload quickshell
matugenApplyScript = pkgs.writeShellScriptBin "matugen-apply" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail
  PATH=${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.swww}/bin:${pkgs.matugen}/bin:$PATH

  pick_img() {
    for p in "$HOME/.cache/wallpaper/current" \
             "$HOME/.local/state/wallpaper/current" \
             "$HOME/.config/wallpaper/current"
    do
      [ -e "$p" ] && echo "$p" && return
    done
    if command -v swww >/dev/null; then
      swww query | sed -n 's/.*[Ii]mage: \(.*\)$/\1/p' | head -n1
    fi
  }

  IMG="$(pick_img || true)"
  if [ -z "${IMG:-}" ] || [ ! -r "$IMG" ]; then
    echo "matugen-apply: no readable wallpaper image found" >&2
    exit 1
  fi

  matugen image "$IMG"

  WR="$HOME/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  [ -x "$WR" ] && "$WR" --silent || true

  systemctl --user try-restart quickshell.service || true
'';

  # One-time venv setup for kde-material-you-colors (what env4 expects)
quickshellVenvSetup = pkgs.writeShellScriptBin "quickshell-venv-setup" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail
  VENV="${venvPath}"

  if [ ! -x "$VENV/bin/python" ]; then
    ${pkgs.python3}/bin/python -m venv "$VENV"
    "$VENV/bin/pip" install --upgrade pip wheel
    "$VENV/bin/pip" install --upgrade kde-material-you-colors
  fi
'';

  # script used by matugen-apply service
in {
  home.username = "chase";
  home.homeDirectory = "/home/chase";
  home.stateVersion = "25.05";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    oh-my-zsh = { enable = true; theme = "robbyrussell"; plugins = [ "git" "sudo" "vi-mode" ]; };
    plugins = [
      { name = "zsh-autosuggestions"; src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh"; }
      { name = "zsh-syntax-highlighting"; src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; }
    ];
  };

  # Packages
  home.packages = with pkgs; [
  (pkgsUnstable.quickshell)

  # portals & polkit
  lxqt.lxqt-policykit

  # wallpaper + basics
  dunst swww wl-clipboard grim slurp swappy wlsunset
  brightnessctl pamixer pavucontrol playerctl rofi kitty

  # tray/network + audio/session
  networkmanagerapplet
  wireplumber
libdbusmenu-gtk3
  fcitx5
  matugen

  # hypr extras (unstable)
  pkgsUnstable.hyprpicker
  pkgsUnstable.hyprshot
  pkgsUnstable.hypridle
  pkgsUnstable.hyprlock
  pkgsUnstable.hyprsunset

  # logout menu
  wlogout
  kdePackages.kimageformats

  # fonts & utils
  noto-fonts noto-fonts-emoji
  nerd-fonts.jetbrains-mono
  nerd-fonts.fira-code
  nerd-fonts.hack
  material-symbols
  shared-mime-info hicolor-icon-theme papirus-icon-theme imagemagick jq yq gojq ripgrep

  pkgsUnstable.qt5.qmake
libsForQt5.qt5.qt3d
libsForQt5.qt5.qtsensors
libsForQt5.qt5.qtserialport
libsForQt5.qt5.qtvirtualkeyboard
libsForQt5.qt5.qtwebchannel
libsForQt5.qt5.qtlottie
libsForQt5.qt5.qtvirtualkeyboard


libsForQt5.qt5.qtcharts
libsForQt5.qt5.qtconnectivity
libsForQt5.qt5.qtdoc
libsForQt5.qt5.qtgraphicaleffects
libsForQt5.qt5.qtimageformats
libsForQt5.qt5.qtlocation
libsForQt5.qt5.qtmultimedia

libsForQt5.qt5.qtquickcontrols
libsForQt5.qt5.qtquickcontrols2
libsForQt5.qt5.qtscript 
libsForQt5.qt5.qttranslations 
libsForQt5.qt5.qtwebview

libsForQt5.qt5.qmake
libsForQt5.qt5.qttools
libsForQt5.qt5.qtbase
libsForQt5.qt5.qtsvg
libsForQt5.qt5.qtwayland
libsForQt5.qt5.qtwebsockets
libsForQt5.qt5.qtx11extras
libsForQt5.qt5.qtxmlpatterns
  pkgsUnstable.qt6.qtdeclarative
  pkgsUnstable.qt6.qtpositioning
  pkgsUnstable.qt6.qtlocation
  pkgsUnstable.qt6.qtmultimedia
  pkgsUnstable.qt6.qtsensors
  pkgsUnstable.qt6.qtsvg
  pkgsUnstable.qt6.qt5compat
  pkgsUnstable.qt6.qtimageformats
  pkgsUnstable.qt6.qtquicktimeline
  pkgsUnstable.qt6.qtvirtualkeyboard
  pkgsUnstable.qt6.qtwayland
  matugenApplyScript
quickshellVenvSetup
  ];

systemd.user.enable = true;
systemd.user.startServices = "sd-switch";
# Start services *as part of* the graphical session
systemd.user.services.quickshell.Unit.PartOf = [ "graphical-session.target" ];
systemd.user.services.swww-daemon.Unit.PartOf = [ "graphical-session.target" ];

# Restore the last wallpaper on login (so colors are correct immediately)
systemd.user.services.wallpaper-restore = {
  Unit = {
    Description = "Restore wallpaper on login";
    After = [ "graphical-session.target" "swww-daemon.service" ];
    PartOf = [ "graphical-session.target" ];
  };
  Service = {
    Type = "oneshot";
    ExecStart = ''
      ${pkgs.bash}/bin/bash -lc '
        if [ -r "$HOME/.cache/wallpaper/current" ]; then
          exec ${pkgs.swww}/bin/swww img "$HOME/.cache/wallpaper/current" --transition-type none
        fi
      '
    '';
  };
  Install.WantedBy = [ "graphical-session.target" ];
};


  # Wallpaper → Matugen auto-apply
systemd.user.services.matugen-apply = {
  Unit = { Description = "Apply Material You colors from current wallpaper"; After = [ "swww-daemon.service" ]; };
  Service = {
    Type = "oneshot";
    Environment = [
      "XDG_CONFIG_HOME=%h/.config"
      "XDG_CACHE_HOME=%h/.cache"
      "XDG_DATA_HOME=%h/.local/share"
      "XDG_STATE_HOME=%h/.local/state"
    ];
    # optional but helpful if you ever harden other units:
    ReadWritePaths = [ "%h" "%t" ];
    ExecStart = "${matugenApplyScript}/bin/matugen-apply";
  };
  Install.WantedBy = [ "graphical-session.target" ];
};


   systemd.user.paths.wallpaper-watch = {
    Unit = { Description = "Watch wallpaper changes"; };
    Path = {
      PathChanged = wallpaperFile;
      Unit = "matugen-apply.service";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
systemd.user.services.quickshell-venv-setup = {
  Unit = { Description = "Create quickshell Python venv for env4 color pipeline"; };
  Service = {
    Type = "oneshot";
    ExecStart = "${quickshellVenvSetup}/bin/quickshell-venv-setup";
  };
  Install.WantedBy = [ "graphical-session.target" ];
};

  # Quickshell service (via wrapper so env is correct)
  systemd.user.services.quickshell = {
    Unit = { Description = "Quickshell (env4 ii)"; After = [ "graphical-session.target" ]; };
    Service = {
      ExecStart = "${pkgsUnstable.quickshell}/bin/quickshell --config %h/.config/quickshell/ii";
      Restart = "on-failure";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        # Let the wrapper prepend its own values; we just extend them here
        # (use empty default when undefined to avoid “undefined variable” failures)
        "QT_PLUGIN_PATH=${pkgsUnstable.qt6.qtsvg}/lib/qt-6/plugins:${pkgsUnstable.qt6.qtimageformats}/lib/qt-6/plugins:${pkgs.kdePackages.kimageformats}/lib/qt-6/plugins:\${QT_PLUGIN_PATH:-}"
        "QML2_IMPORT_PATH=${pkgsUnstable.qt6.qt5compat}/lib/qt-6/qml:${pkgsUnstable.qt6.qtpositioning}/lib/qt-6/qml:${pkgsUnstable.qt6.qtlocation}/lib/qt-6/qml:${pkgsUnstable.qt6.qtmultimedia}/lib/qt-6/qml:${pkgsUnstable.qt6.qtsensors}/lib/qt-6/qml:\${QML2_IMPORT_PATH:-}"
        "QML_IMPORT_PATH=${pkgsUnstable.qt6.qtdeclarative}/lib/qt-6/qml:\${QML_IMPORT_PATH:-}"
        # Icon theme + search paths (Papirus is what env4 expects)
        "QT_ICON_THEME=Papirus"
        "XDG_DATA_DIRS=%h/.local/share:${config.home.profileDirectory}/share:/run/current-system/sw/share:${pkgs.papirus-icon-theme}/share:${pkgs.hicolor-icon-theme}/share:${pkgs.shared-mime-info}/share"
      ];
    };
    Install.WantedBy = wanted;
  };

  # Other user services
  systemd.user.services = {
    fcitx5 = {
      Unit = { Description = "fcitx5"; After = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.fcitx5}/bin/fcitx5"; Restart = "on-failure"; };
      Install.WantedBy = wanted;
    };

    swww-daemon = {
      Unit = { Description = "swww wallpaper daemon"; After = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.swww}/bin/swww-daemon"; Restart = "always"; };
      Install.WantedBy = wanted;
    };

    dunst = {
      Unit = { Description = "Dunst notification daemon"; After = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.dunst}/bin/dunst -config %h/.config/dunst/dunstrc"; Restart = "on-failure"; };
      Install.WantedBy = wanted;
    };

    polkit-agent = {
      Unit = { Description = "PolicyKit Authentication Agent"; After = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent"; Restart = "on-failure"; };
      Install.WantedBy = wanted;
    };

    cliphist-text = {
      Unit = { Description = "cliphist (text clipboard)"; After = [ "graphical-session.target" ]; };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "always";
      };
      Install.WantedBy = wanted;
    };

    cliphist-primary = {
      Unit = { Description = "cliphist (primary selection)"; After = [ "graphical-session.target" ]; };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste -p -t text --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "always";
      };
      Install.WantedBy = wanted;
    };

    swayidle = {
      Unit = { Description = "Idle management for swaylock"; After = [ "graphical-session.target" ]; };
      Service = {
        ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.swaylock-effects}/bin/swaylock -f -c 000000' timeout 600 'systemctl suspend'";
        Restart = "always";
      };
      Install.WantedBy = wanted;
    };
  };

  programs.starship = { enable = true; enableZshIntegration = true; };
  fonts.fontconfig.enable = true;

    #wayland.windowManager.hyprland = {
    #enable = true;
    # package = pkgsUnstable.hyprland;
    #};

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE    = "kvantum";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE  = "fcitx";
    XMODIFIERS    = "@im=fcitx";
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = venvPath;
    TERMINAL = "kitty";
  };
  xdg.enable = true;
  xdg.configFile = disableSet;

home.activation.configSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  set -euxo pipefail
  src="${cfgDot}"

  while IFS= read -r -d $'\0' path; do
    rel="''${path#"$src/"}"
    [ -z "$rel" ] && continue
    d="$HOME/.config/$rel"

    case "$rel" in
    	systemd|systemd/*) continue ;;
	fontconfig|fontconfig/*) continue ;;
    esac

    if [ -L "$d" ] && [[ "$(readlink -f "$d")" == /nix/store/* ]]; then
      rm -f "$d"
    fi

    if [ ! -e "$d" ]; then
      echo "Config sync: seeding $d from $src"
      mkdir -p "$(dirname "$d")"
      cp -a --no-preserve=mode,ownership "$path" "$d"
    fi
  done < <(find "$src" -mindepth 1 -print0)
'';


home.activation.materialYouWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  make_writable_dir() {
    local src="$1" dst="$2"
    if [ -L "$dst" ]; then rm -f "$dst"; fi
    if [ ! -d "$dst" ]; then
      mkdir -p "$dst"
      cp -r --no-preserve=mode,ownership "$src"/. "$dst"/ 2>/dev/null || true
    fi
  }

  make_writable_dir "${cfgDot}/Kvantum"                 "$HOME/.config/Kvantum"
  make_writable_dir "${cfgDot}/qt6ct"                   "$HOME/.config/qt6ct"
  make_writable_dir "${cfgDot}/kde-material-you-colors" "$HOME/.config/kde-material-you-colors"
  make_writable_dir "${cfgDot}/fuzzel"                  "$HOME/.config/fuzzel"
  make_writable_dir "${cfgDot}/hypr"   "$HOME/.config/hypr"
  make_writable_dir "${cfgDot}/matugen"                 "$HOME/.config/matugen"
  make_writable_dir "${cfgDot}/kitty" "$HOME/.config/kitty"

  # if kdeglobals was symlinked, turn it into a real file
  if [ -L "$HOME/.config/kdeglobals" ]; then
    tmp="$(mktemp)"; cp -L "$HOME/.config/kdeglobals" "$tmp" 2>/dev/null || true
    rm -f "$HOME/.config/kdeglobals"
    install -Dm644 "$tmp" "$HOME/.config/kdeglobals"
  fi
'';
 programs.home-manager.enable = true;
}

