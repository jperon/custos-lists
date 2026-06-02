-- lists/ci/config.moon
-- Configuration minimale dédiée à la CI de compilation des listes.
--
-- Chargée par lua/filter/updater.lua (runtime custos cloné à une révision
-- épinglée par le workflow). Seules les clés filter.* utiles à la compilation
-- des .bin sont définies ; tout le reste vient des défauts de src/config.moon.
--
-- Les chemins sont relatifs à $LISTS_ROOT (racine du dépôt custos-lists),
-- injecté par le workflow GitHub Actions. En local :
--   LISTS_ROOT=$PWD CUSTOS_CONFIG_PATH=ci/config.moon luajit /chemin/updater.lua

root = (os.getenv("LISTS_ROOT") or ".")\gsub("/+$", "")

{
  filter: {
    -- Racine de sortie des .bin. Les listes custom vont dans <root>/custom,
    -- les catégories Toulouse dans <root>/toulouse (via subdir ci-dessous).
    domainlists_dir: root

    -- Sources .txt versionnées : scan automatique de <custom_lists_dir>/*.txt
    -- → <domainlists_dir>/custom/<nom>.bin
    custom_lists_dir: root .. "/custom"

    sources: {
      -- DSI UT Capitole : tar.gz multi-catégories → un .bin par catégorie
      -- dans <domainlists_dir>/toulouse/. Toutes les catégories (pas de
      -- filtre `categories`), pour la release « full ».
      toulouse: {
        url:    "https://dsi.ut-capitole.fr/blacklists/download/blacklists.tar.gz"
        format: "toulouse"
        subdir: "toulouse"
      }
    }
  }
}
