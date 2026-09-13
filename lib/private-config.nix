source: let
  privateConfig =
    if builtins.pathExists (source + "/default.nix")
    then import source
    else {};
  privateHosts =
    if builtins.isAttrs privateConfig && privateConfig ? hosts
    then privateConfig.hosts
    else {};
  privateVm =
    if builtins.isAttrs privateHosts && privateHosts ? vm
    then privateHosts.vm
    else {};
  vmUser =
    if builtins.isAttrs privateVm && privateVm ? user
    then privateVm.user
    else "ci-user";
  validPrivateConfig =
    builtins.isAttrs privateConfig
    && builtins.isAttrs privateHosts
    && builtins.isAttrs privateVm
    && builtins.isString vmUser;
in
  if !validPrivateConfig
  then throw "privateConfig metadata must be an attribute set; hosts.vm.user, when supplied, must be a string"
  else {inherit vmUser;}
