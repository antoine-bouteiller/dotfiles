# Skill discovery: the local tree lives at the repo root (`agents/skills`) so it can be
# edited in place, and every SKILL.md-bearing directory becomes one entry. Renders the
# home.file set for a single agent dir, e.g. ".agents" or ".claude".
{
  lib,
  inputs,
  mkOutOfStoreSymlink,
  agentsDir,
}: let
  root = ../../../agents/skills;

  findSkills = relPath: let
    fullPath = root + (lib.optionalString (relPath != "") "/${relPath}");
    entries = builtins.readDir fullPath;
    dirs = lib.filterAttrs (_: type: type == "directory") entries;
  in
    lib.concatLists (
      lib.mapAttrsToList (
        name: _: let
          subRelPath =
            if relPath == ""
            then name
            else "${relPath}/${name}";
          subEntries = builtins.readDir (root + "/${subRelPath}");
          hasSkillMd = subEntries ? "SKILL.md";
        in
          if hasSkillMd
          then [
            {
              name = lib.replaceStrings ["/"] [":"] subRelPath;
              path = subRelPath;
            }
          ]
          else findSkills subRelPath
      )
      dirs
    );

  skills = findSkills "";

  # External skills pinned as flake inputs, symlinked into every agent's
  # skills dir so they stay available even without claude-code.
  externalSkills = {
    agent-browser = "${inputs.agent-browser-skill}/skills/agent-browser";
  };
in
  dir:
    builtins.listToAttrs (
      (map (skill: {
          name = "${dir}/skills/${skill.name}";
          value.source = mkOutOfStoreSymlink "${agentsDir}/skills/${skill.path}";
        })
        skills)
      ++ lib.mapAttrsToList (name: path: {
        name = "${dir}/skills/${name}";
        value.source = path;
      })
      externalSkills
    )
