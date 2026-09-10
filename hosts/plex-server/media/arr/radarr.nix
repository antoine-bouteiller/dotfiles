{
  config,
  lib,
  ...
}:
import ./shared.nix {
  inherit config lib;
  name = "radarr";
  managesMedia = true;
}
