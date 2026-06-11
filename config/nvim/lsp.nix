{ ... }:
{
  # LSP configuration via astrolsp.
  # Disables automatic codelens (opts.features.codelens = false) and manually
  # enables it per-buffer in on_attach so it only activates when the server
  # actually supports it.
  #
  # Note: LSP servers are installed by AstroNvim's community packs via Mason.
  # On NixOS, replace Mason with extraPackages in nvim.nix if needed.
  xdg.configFile = {
    "nvim/lua/plugins/astrolsp.lua".source = ./lua/plugins/astrolsp.lua;
  };
}
