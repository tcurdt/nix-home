{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.my.forgejo;
  hasDomainCertificate = cfg.domain_crt != null && cfg.domain_key != null;
  oidcIssuer = if cfg.oidc.issuer == "" then "" else "https://${cfg.oidc.issuer}";
in
{
  options.services.my.forgejo = {
    server = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "git.example.org";
      description = "Public Forgejo server name. Empty disables the service.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address Forgejo listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port Forgejo listens on.";
    };

    lfs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Forgejo LFS support.";
    };

    selfRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to disable self-service Forgejo registration.";
    };

    domain_crt = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/git.example.org/server.crt";
      description = "Path to a pre-existing TLS certificate. Must be set together with domain_key.";
    };

    domain_key = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/git.example.org/server.key";
      description = "Path to a pre-existing TLS private key. Must be set together with domain_crt.";
    };

    oidc = {
      issuer = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "id.example.org";
        description = "OIDC issuer URL or hostname. Empty disables OIDC bootstrap.";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "pocket-id";
        description = "Forgejo authentication source name.";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "forgejo";
        description = "OIDC client ID used by Forgejo.";
      };

      clientSecretPath = lib.mkOption {
        type = lib.types.str;
        default = "/secrets/forgejo/oidc-client-secret";
        description = "File containing the Forgejo OIDC client secret.";
      };

    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra Forgejo settings merged over the module defaults.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "https://${cfg.server}/";
      description = "Derived public Forgejo root URL.";
    };
  };

  config = lib.mkIf (cfg.server != "") {
    assertions = [
      {
        assertion = (cfg.domain_crt == null) == (cfg.domain_key == null);
        message = "services.my.forgejo.domain_crt and services.my.forgejo.domain_key must be set together.";
      }
      {
        assertion = hasDomainCertificate || config.services.my.webserver.acme != null;
        message = "services.my.forgejo requires a certificate pair or services.my.webserver.acme to be set.";
      }
    ];

    services.forgejo = {
      enable = true;
      lfs.enable = cfg.lfs;

      settings = lib.recursiveUpdate {
        server = {
          DOMAIN = cfg.server;
          ROOT_URL = cfg.url;
          HTTP_ADDR = cfg.address;
          HTTP_PORT = cfg.port;
        };

        service = {
          DISABLE_REGISTRATION = !cfg.selfRegistration;
        }
        // lib.optionalAttrs (oidcIssuer != "") {
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
          ENABLE_BASIC_AUTHENTICATION = false;
          ENABLE_PASSWORD_SIGNIN_FORM = false;
          ENABLE_PASSKEY_AUTHENTICATION = false;
        };
        oauth2_client = lib.optionalAttrs (oidcIssuer != "") {
          ACCOUNT_LINKING = "auto";
          ENABLE_AUTO_REGISTRATION = true;
          REGISTER_EMAIL_CONFIRM = false;
          USERNAME = "preferred_username";
        };
        session.COOKIE_SECURE = true;
      } cfg.extraSettings;
    };

    services.my.webserver.virtualHosts.${cfg.server} = {
      locations."/" = {
        proxyPass = "http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 512M;
        '';
      };
    }
    // lib.optionalAttrs hasDomainCertificate {
      enableACME = false;
      sslCertificate = cfg.domain_crt;
      sslCertificateKey = cfg.domain_key;
    };

    systemd.services.forgejo-bootstrap-oidc = lib.mkIf (oidcIssuer != "") {
      wantedBy = [ "multi-user.target" ];
      after = [ "forgejo.service" ];
      requires = [ "forgejo.service" ];
      path = [
        config.services.forgejo.package
        pkgs.gawk
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "forgejo";
        Group = "forgejo";
      };
      script = ''
        auth_id="$(
          forgejo admin auth list --config /var/lib/forgejo/custom/conf/app.ini \
            | awk -F '\t' -v name=${lib.escapeShellArg cfg.oidc.name} '$2 == name { print $1 }'
        )"

        if [ -n "$auth_id" ]; then
          forgejo admin auth update-oauth \
            --config /var/lib/forgejo/custom/conf/app.ini \
            --id "$auth_id" \
            --name ${lib.escapeShellArg cfg.oidc.name} \
            --provider openidConnect \
            --key ${lib.escapeShellArg cfg.oidc.clientId} \
            --secret "$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg cfg.oidc.clientSecretPath})" \
            --auto-discover-url ${lib.escapeShellArg "${oidcIssuer}/.well-known/openid-configuration"} \
            --skip-local-2fa \
            --scopes openid --scopes email --scopes profile
        else
          forgejo admin auth add-oauth \
            --config /var/lib/forgejo/custom/conf/app.ini \
            --name ${lib.escapeShellArg cfg.oidc.name} \
            --provider openidConnect \
            --key ${lib.escapeShellArg cfg.oidc.clientId} \
            --secret "$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg cfg.oidc.clientSecretPath})" \
            --auto-discover-url ${lib.escapeShellArg "${oidcIssuer}/.well-known/openid-configuration"} \
            --skip-local-2fa \
            --scopes openid --scopes email --scopes profile
        fi
      '';
    };
  };
}
