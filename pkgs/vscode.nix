let
  drv =
    { vscode-with-extensions
    , vscode-extensions
    }:

    vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        ms-python.python
        ms-vsliveshare.vsliveshare
        vscodevim.vim
      ];
    };

  # This currently (January 22, 2021) requires nixpkgs-unstable.
  commit = "fd0daed2e8d590418fc565de70ea6ca47a6d2dcb";
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/${commit}.tar.gz";
in
with import nixpkgs
{
  config = {
    allowUnfree = true;
  };
}; callPackage drv { }
