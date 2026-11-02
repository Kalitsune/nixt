{ lib, config, ... }:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Global nixt library helper functions.";
  };

  config.flake.lib = {
    isLoaded =
      arg1:
      let
        check =
          pkg:
          let
            names =
              let
                raw = if builtins.isList pkg then pkg else [ pkg ];
              in
              map (x: if builtins.isString x then x else lib.getName x) raw;

            flakePkgs = builtins.concatLists (
              builtins.attrValues (builtins.mapAttrs (_: p: builtins.attrNames p) (config.flake.packages or { }))
            );

            nixosConfigs = builtins.attrValues (config.flake.nixosConfigurations or { });

            isProgramOrService = lib.any (
              name:
              lib.any (
                c:
                (c.config.programs ? ${name} && c.config.programs.${name}.enable or false)
                || (c.config.services ? ${name} && c.config.services.${name}.enable or false)
              ) nixosConfigs
            ) names;

            collectFiles =
              m:
              (if m ? _file then [ (builtins.head (lib.splitString ", " m._file)) ] else [ ])
              ++ (if m ? imports then builtins.concatMap collectFiles m.imports else [ ]);

            configFiles = lib.concatMap (
              c:
              builtins.filter (f: builtins.isString f && builtins.pathExists f && !(lib.hasInfix "#" f)) (
                builtins.concatMap collectFiles (c.options._module.args.value.modules or [ ])
              )
            ) nixosConfigs;

            isMentionedInModules = lib.any (
              name:
              builtins.any (
                f: builtins.match ".*[^a-zA-Z0-9_-]${name}[^a-zA-Z0-9_-].*" (builtins.readFile f) != null
              ) configFiles
            ) names;

            isFlakePkg = lib.any (name: lib.elem name flakePkgs) names;
          in
          isFlakePkg || isProgramOrService || isMentionedInModules;
      in
      if arg1 ? environment || arg1 ? config.environment then check else check arg1;
  };
}
