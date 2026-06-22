{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.system}.niri;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; 

      settings = let
	noctalia_exe = lib.getExe self'.packages.noctalia-shell;
	wpctl_exe = lib.getExe' pkgs.wireplumber "wpctl";
      in {
	spawn-at-startup = [
	  noctalia_exe
	];

	xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
	
	input = {
	  focus-follows-mouse = _: {};
	  keyboard.xkb.layout = "us";
	  touchpad = {
	    tap = _: {};
	    natural-scroll = _: {};
	  };
	};

	layout.gaps = 5;

	# noctalia settings (see: https://docs.noctalia.dev/v4/getting-started/compositor-settings/niri/)
	window-rule = {
	  geometry-corner-radius = 20;
	  clip-to-geometry = true;
	};
	debug.honor-xdg-activation-with-invalid-serial = _: {};

	binds = {
	  # Dedicated Launchers
	  "Mod+T".spawn-sh = lib.getExe self'.packages.terminal;
	  "Mod+Escape".spawn-sh = "${noctalia_exe} ipc call lockScreen lock";
	  "Print".screenshot = _: { 
	    props.show-pointer = false;
	  };
	  
	  # Window Controls
	  "Mod+X".close-window = _: {};

	  # App Launcher, Clipboard history, Emoji Picker, Power Menu.
	  "Mod+Space".spawn-sh = "${noctalia_exe} ipc call launcher toggle";
	  "Mod+V".spawn-sh = "${noctalia_exe} ipc call launcher clipboard";
	  "Mod+semicolon".spawn-sh = "${noctalia_exe} ipc call launcher emoji";
	  "Mod+M".spawn-sh = "${noctalia_exe} ipc call sessionMenu toggle";

	  # Media Controls
	  "XF86AudioRaiseVolume" = _: {
	    props.allow-when-locked=true;
	    content.spawn-sh = "${wpctl_exe} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
	  };
	  "XF86AudioLowerVolume" = _: {
	    props.allow-when-locked=true;
	    content.spawn-sh = "${wpctl_exe} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
	  };
	  "XF86AudioMute" = _: {
	    props.allow-when-locked=true;
	    content.spawn-sh = "${wpctl_exe} set-mute @DEFAULT_AUDIO_SINK@ toggle";
	  };
	  "XF86AudioMicMute" = _: {
	    props.allow-when-locked=true;
	    content.spawn-sh = "${wpctl_exe} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
	  };

	  # Brightness Controls
	  "XF86MonBrightnessUp" = _: {
	    props.allow-when-locked=true;
	    content.spawn-sh = "${lib.getExe pkgs.brightnessctl} s 10%+";
	  };
	  "XF86MonBrightnessDown" = _: {
	    props.allow-when-locked=true;
	    content.spawn-sh = "${lib.getExe pkgs.brightnessctl} s 10%-";
	  };

	  # Focus Relative Windows
	  "Mod+Up".focus-window-up = _: {};
	  "Mod+Down".focus-window-down = _: {};
	  "Mod+Left".focus-column-left = _: {};
	  "Mod+Right".focus-column-right = _: {};
	  "Mod+J".focus-window-up = _: {}; # And vim bindings too because why not
	  "Mod+K".focus-window-down = _: {};
	  "Mod+L".focus-column-left = _: {};
	  "Mod+H".focus-column-right = _: {};

	  # Move Relative Windows
	  "Mod+Shift+Up".move-window-up = _: {};
	  "Mod+Shift+Down".move-window-down = _: {};
	  "Mod+Shift+Left".move-column-left = _: {};
	  "Mod+Shift+Right".move-column-right = _: {};
	  "Mod+Shift+J".move-window-up = _: {}; # And vim bindings too because why not
	  "Mod+Shift+K".move-window-down = _: {};
	  "Mod+Shift+L".move-column-left = _: {};
	  "Mod+Shift+H".move-column-right = _: {};

	  # Go to workspace #n
	  "Mod+1".focus-workspace = 1;
	  "Mod+2".focus-workspace = 2;
	  "Mod+3".focus-workspace = 3;
	  "Mod+4".focus-workspace = 4;
	  "Mod+5".focus-workspace = 5;
	  "Mod+6".focus-workspace = 6;
	  "Mod+7".focus-workspace = 7;
	  "Mod+8".focus-workspace = 8;
	  "Mod+9".focus-workspace = 9;
	  "Mod+0".focus-workspace = 10;

	  # Move to workspace #n
	  "Mod+Shift+1".move-column-to-workspace = 1;
	  "Mod+Shift+2".move-column-to-workspace = 2;
	  "Mod+Shift+3".move-column-to-workspace = 3;
	  "Mod+Shift+4".move-column-to-workspace = 4;
	  "Mod+Shift+5".move-column-to-workspace = 5;
	  "Mod+Shift+6".move-column-to-workspace = 6;
	  "Mod+Shift+7".move-column-to-workspace = 7;
	  "Mod+Shift+8".move-column-to-workspace = 8;
	  "Mod+Shift+9".move-column-to-workspace = 9;
	  "Mod+Shift+0".move-column-to-workspace = 10;
	  
	  # Resize options
	  "Mod+Ctrl+Up".set-window-height = "+5%";
	  "Mod+Ctrl+Down".set-window-height = "-5%";
	  "Mod+Ctrl+Right".set-column-width = "+5%";
	  "Mod+Ctrl+Left".set-column-width = "-5%";

	  "Mod+Ctrl+K".set-window-height = "+5%";
	  "Mod+Ctrl+J".set-window-height = "-5%";
	  "Mod+Ctrl+L".set-column-width = "+5%";
	  "Mod+Ctrl+H".set-column-width = "-5%";
	};
      };
    };
  };
}
