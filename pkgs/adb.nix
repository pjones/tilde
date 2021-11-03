# A shell environment that includes adb and a script to debloat
# Samsung devices.
let
  sources = import ../nix/sources.nix;

  pkgs = import sources.nixpkgs {
    config = {
      android_sdk.accept_license = true;
    };
  };

  inherit (pkgs) lib;

  samsungDebloat =
    let
      uninstall = [
        # Don't save clipboard history:
        "com.samsung.clipboardsaveservice"
        "com.samsung.android.app.clipboardedge"

        # Samsung apps that I don't use:
        "com.samsung.android.calendar"

        # Fuck you Facebook:
        "com.facebook.services"
        "com.facebook.katana"
        "com.facebook.system"
        "com.facebook.appmanager"
      ];
    in
    pkgs.writeScriptBin "samsung-debloat"
      ((lib.concatMapStringsSep "\n"
        (pkg: "adb shell pm uninstall -k --user 0 ${pkg}")
        uninstall)
      + ''
        # Clean up:
        adb kill-server
      '');
in
pkgs.mkShell {
  name = "android-env";

  buildInputs = [
    samsungDebloat
    pkgs.androidsdk_9_0

    # NixOS 21.11:
    # pkgs.android-tools
  ];
}

