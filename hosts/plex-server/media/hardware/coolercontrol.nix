_: let
  constants = import ../shared/constants.nix;
in {
  programs.coolercontrol.enable = true;

  local.media.coolercontrol = {
    port = constants.coolercontrol.port;
    auth = true;
  };
}
