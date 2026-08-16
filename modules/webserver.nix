{
  config,
  lib,
  # pkgs,
  ...
}:

let
  cfg = config.services.my.webserver;
in
{
  options.services.my.webserver = {
    enable = lib.mkEnableOption "Webserver enable";

    acme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "email@example.com";
      description = "Email address used for ACME registration. Setting it enables ACME by default.";
    };

    forceSSL = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether service modules should force SSL for registered nginx virtual hosts.";
    };

    virtualHosts = lib.mkOption {
      default = { };
      description = "Public virtual host definitions registered by service modules.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = lib.types.attrsOf lib.types.anything;
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      # package = lib.mkDefault pkgs.angie;

      virtualHosts = lib.mapAttrs (
        _: vhost:
        {
          enableACME = cfg.acme != null;
        }
        // vhost
        // {
          forceSSL = cfg.forceSSL;
        }
      ) cfg.virtualHosts;
    };

    security.acme = lib.mkIf (cfg.acme != null) {
      acceptTerms = true;
      defaults.email = cfg.acme;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
