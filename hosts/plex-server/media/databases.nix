[
  {
    name = "radarr";
    user = "radarr";
    extraDatabases = ["radarr-log"];
  }
  {
    name = "sonarr";
    user = "sonarr";
    extraDatabases = ["sonarr-log"];
  }
  {
    name = "prowlarr";
    user = "prowlarr";
    extraDatabases = ["prowlarr-log"];
  }
  {
    name = "bazarr";
    user = "bazarr";
  }
  {
    name = "autoscan";
    user = "autoscan";
  }
  {
    name = "immich";
    user = "immich";
    setupScript = ''
      psql -d immich -tAc "CREATE EXTENSION IF NOT EXISTS vector"
      psql -d immich -tAc "CREATE EXTENSION IF NOT EXISTS vchord CASCADE"
    '';
  }
]
