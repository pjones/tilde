# A shell environment that includes adb and a script to debloat
# Samsung devices.
{ pkgs ? import <nixpkgs> {
    config.android_sdk.accept_license = true;
  }
}:
let
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
    pkgs.android-tools
  ];
}

