{ writers }:

writers.writePython3 "wg-gen" {
  doCheck = false; # I don't use flake8
} ./wg-gen.py
