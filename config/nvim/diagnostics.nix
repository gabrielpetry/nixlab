{ ... }: {
  programs.nixvim.diagnostic.settings = {
    severity_sort = true;
    update_in_insert = false;
    virtual_text = {
      spacing = 2;
      source = "if_many";
    };
    float = {
      border = "rounded";
      source = "if_many";
    };
  };
}
