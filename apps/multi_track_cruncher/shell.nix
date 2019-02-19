let

nixpkgs = import ./nixpkgs.nix;

in

{ pkgs ? import nixpkgs {} }:

with pkgs;

mkShell {
  buildInputs = [ mpg123 lame ffmpeg openal ];  # note that openal builds openal-soft (which is what we want)
}
