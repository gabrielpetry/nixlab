{ ... }:
{
  # Treesitter parser configuration and custom query files.
  # treesitter.lua: ensures lua + vim parsers are installed; disables markdown
  #                 and markdown_inline highlighting to avoid Neovim 0.12 crash.
  # after/queries/yaml/injections.scm:  injects PromQL into YAML `expr` fields.
  # after/queries/yaml/highlights.scm:  custom YAML key/value highlight groups.
  # after/queries/promql/highlights.scm: highlights PromQL label values.
  xdg.configFile = {
    "nvim/lua/plugins/treesitter.lua".source = ./lua/plugins/treesitter.lua;

    "nvim/after/queries/yaml/highlights.scm".source = ./after/queries/yaml/highlights.scm;
    "nvim/after/queries/yaml/injections.scm".source = ./after/queries/yaml/injections.scm;
    "nvim/after/queries/promql/highlights.scm".source = ./after/queries/promql/highlights.scm;
  };
}
