{
  description = "Nix and dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      disko,
      home-manager,
      nixvim,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      neovimModule = {
        _module.args = {
          nixvimLib = nixvim.lib.nixvim;
          nvimPkgs = pkgs;
        };
        imports = [
          nixvim.homeModules.nixvim
          ./config/nvim/nvim.nix
        ];
      };

      envUserConfigPath = builtins.getEnv "NIXLAB_USER_CONFIG";
      userConfigPath =
        if envUserConfigPath != "" then
          envUserConfigPath
        else if builtins.pathExists ./user-config.nix then
          ./user-config.nix
        else
          null;
      userConfig = if userConfigPath != null then import userConfigPath else { };
      username = userConfig.username or "user";
      homeDirectory = userConfig.homeDirectory or "/home/user";
    in
    {
      packages.${system} = {
        nixos-anywhere = pkgs.nixos-anywhere;
        nixos-rebuild = pkgs.nixos-rebuild;
      };

      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            _module.args = {
              inherit username homeDirectory;
            };
          }
          ./config/home.nix
          ./config/packages.nix
          {
            home.packages = [ pkgs.devbox ];
          }
          ./config/environment.nix
          ./tooling/tooling.nix
          neovimModule
          ./config/tmux/tmux.nix
          ./config/bash/bash.nix
          ./config/starship/starship.nix
          ./config/kde.nix
          ./nixosModules/bws/bws.nix
          ./nixosModules/coding-agents/pi.nix
        ];
      };

      nixosConfigurations = import ./nixosAnywhere {
        inherit system username userConfig;
        inputs = {
          inherit nixpkgs disko;
        };
      };

      nixosModules = {
        bws = import ./nixosModules/bws/bws.nix;
      };

      homeModules = {
        bws = import ./nixosModules/bws/bws.nix;
        packages = import ./config/packages.nix;
        environment = import ./config/environment.nix;
        bash = import ./config/bash/bash.nix;
        starship = import ./config/starship/starship.nix;
        kde = import ./config/kde.nix;
        tmux = import ./config/tmux/tmux.nix;
        neovim = neovimModule;
        tooling = import ./tooling/tooling.nix;
      };

      lib = (
        import ./nixosAnywhere/lib.nix {
          inputs = {
            inherit nixpkgs disko;
          };
        }
      );
    };
}
