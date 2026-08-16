{
  config,
  lib,
  ...
}:

let
  cfg = config.services.my.grafana;
  hasDomainCertificate = cfg.domain_crt != null && cfg.domain_key != null;
  listen = "${cfg.address}:${toString cfg.port}";
  oidcIssuer =
    if cfg.oidc.issuer == "" then
      ""
    else if lib.hasPrefix "http://" cfg.oidc.issuer || lib.hasPrefix "https://" cfg.oidc.issuer then
      cfg.oidc.issuer
    else
      "https://${cfg.oidc.issuer}";
in
{
  imports = [
    ./webserver.nix
  ];

  options.services.my.grafana = {
    enable = lib.mkEnableOption "grafana";

    server = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "grafana.example.org";
      description = "Public server name for Grafana. Null disables nginx registration.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address Grafana listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "Port Grafana listens on.";
    };

    domain_crt = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/grafana.example.org/server.crt";
      description = "Path to a pre-existing TLS certificate. Must be set together with domain_key.";
    };

    domain_key = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/grafana.example.org/server.key";
      description = "Path to a pre-existing TLS private key. Must be set together with domain_crt.";
    };

    # sudo sh -c 'openssl rand -hex 32 | tr -d "\n" > /secrets/grafana/secret.key'
    secretKeyPath = lib.mkOption {
      type = lib.types.str;
      default = "/secrets/grafana/secret.key";
      description = "File containing Grafana's secret_key.";
    };

    oidc = {
      issuer = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "id.example.org";
        description = "OIDC issuer URL or hostname. Empty disables OIDC login.";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "grafana";
        description = "OIDC client ID used by Grafana.";
      };

      # sudo sh -c 'openssl rand -hex 32 | tr -d "\n" > /secrets/grafana/oidc-client-secret'
      clientSecretPath = lib.mkOption {
        type = lib.types.str;
        default = "/secrets/grafana/oidc-client-secret";
        description = "File containing the Grafana OIDC client secret.";
      };

      scopes = lib.mkOption {
        type = lib.types.str;
        default = "openid profile email";
        description = "OIDC scopes requested by Grafana.";
      };

      allowSignUp = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether Grafana may create users from OIDC logins.";
      };

      adminGroup = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "[A-Za-z0-9_]+");
        default = null;
        example = "grafana_admins";
        description = "Pocket ID group whose members receive Grafana administrator privileges.";
      };

      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "Extra auth.generic_oauth settings merged over the OIDC defaults.";
      };
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra Grafana settings merged over the module defaults.";
    };

    provision = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Grafana provisioning settings.";
    };

    url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      default = if cfg.server == null then null else "https://${cfg.server}/";
      description = "Derived public Grafana root URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.domain_crt == null) == (cfg.domain_key == null);
        message = "services.my.grafana.domain_crt and services.my.grafana.domain_key must be set together.";
      }
      {
        assertion = cfg.server == null || hasDomainCertificate || config.services.my.webserver.acme != null;
        message = "services.my.grafana requires a certificate pair or services.my.webserver.acme to be set.";
      }
    ];

    systemd.tmpfiles.rules =
      [ "z ${cfg.secretKeyPath} 0640 root grafana - -" ]
      ++ lib.optional (oidcIssuer != "") "z ${cfg.oidc.clientSecretPath} 0640 root grafana - -"
      ++ lib.optionals hasDomainCertificate [
        "z ${cfg.domain_crt} 0644 root nginx - -"
        "z ${cfg.domain_key} 0640 root nginx - -"
      ];

    services.grafana = {
      enable = true;
      settings =
        lib.recursiveUpdate
          {
            analytics.reporting_enabled = false;
            auth = lib.optionalAttrs (oidcIssuer != "") {
              disable_login_form = true;
              oauth_auto_login = true;
            };
            "auth.basic".enabled = oidcIssuer == "";
            server = {
              http_addr = cfg.address;
              http_port = cfg.port;
            }
            // lib.optionalAttrs (cfg.server != null) {
              domain = cfg.server;
              root_url = cfg.url;
            };
            security = {
              admin_user = "admin";
              admin_email = "admin@localhost";
              admin_password = "admin";
              secret_key = "$__file{${cfg.secretKeyPath}}";
            };
          }
          (
            lib.recursiveUpdate (lib.optionalAttrs (oidcIssuer != "") {
              "auth.generic_oauth" = {
                enabled = true;
                name = "Pocket ID";
                allow_sign_up = cfg.oidc.allowSignUp;
                client_id = cfg.oidc.clientId;
                client_secret = "$__file{${cfg.oidc.clientSecretPath}}";
                scopes = cfg.oidc.scopes + lib.optionalString (cfg.oidc.adminGroup != null) " groups";
                auth_url = "${oidcIssuer}/authorize";
                token_url = "${oidcIssuer}/api/oidc/token";
                api_url = "${oidcIssuer}/api/oidc/userinfo";
                use_pkce = true;
              }
              // lib.optionalAttrs (cfg.oidc.adminGroup != null) {
                allow_assign_grafana_admin = true;
                role_attribute_path = "contains(groups[*], '${cfg.oidc.adminGroup}') && 'GrafanaAdmin' || 'Viewer'";
                role_attribute_strict = true;
              }
              // cfg.oidc.settings;
            }) cfg.settings
          );
      provision = cfg.provision;
    };

    services.my.webserver = lib.mkIf (cfg.server != null) {
      enable = true;
      virtualHosts.${cfg.server} = {
        locations."/" = {
          proxyPass = "http://${listen}";
          proxyWebsockets = true;
        };
      }
      // lib.optionalAttrs hasDomainCertificate {
        enableACME = false;
        sslCertificate = cfg.domain_crt;
        sslCertificateKey = cfg.domain_key;
      };
    };
  };
}
