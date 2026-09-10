{
  config,
  lib,
  ...
}:
import ./shared.nix {
  inherit config lib;
  name = "prowlarr";
  managesMedia = false;
}
