# Renders the home.file set of external and extra skills for a single agent
# dir, e.g. ".agents" or ".claude".
{
  lib,
  inputs,
  extraSkills ? {},
}: let
  # External skills pinned as flake inputs, symlinked into every agent's
  # skills dir so they stay available even without claude-code.
  externalSkills = {
    agent-browser = "${inputs.agent-browser-skill}/skills/agent-browser";
  };
in
  dir:
    lib.mapAttrs' (name: path: {
      name = "${dir}/skills/${name}";
      value.source = path;
    })
    (externalSkills // extraSkills)
