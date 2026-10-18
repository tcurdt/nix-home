{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.my.paperless;
  hasDomainCertificate = cfg.domain_crt != null && cfg.domain_key != null;
  oidcIssuer =
    if cfg.oidc.issuer == "" then
      ""
    else if lib.hasPrefix "http://" cfg.oidc.issuer || lib.hasPrefix "https://" cfg.oidc.issuer then
      cfg.oidc.issuer
    else
      "https://${cfg.oidc.issuer}";

  paperlessGroup = config.users.users.${config.services.paperless.user}.group;

  # PAPERLESS_SOCIALACCOUNT_PROVIDERS has to carry the client secret inline,
  # so it is rendered at runtime into an EnvironmentFile outside the nix store.
  oidcEnvFile = "/run/paperless-oidc.env";
  oidcProviders = pkgs.writeText "paperless-oidc-providers.json" (
    builtins.toJSON {
      openid_connect = {
        SCOPE = [
          "openid"
          "profile"
          "email"
        ]
        ++ lib.optional (cfg.oidc.adminGroup != null) "groups";
        OAUTH_PKCE_ENABLED = true;
        APPS = [
          {
            provider_id = cfg.oidc.providerId;
            name = cfg.oidc.name;
            client_id = cfg.oidc.clientId;
            secret = "";
            settings.server_url = oidcIssuer;
          }
        ];
      };
    }
  );

  paperlessUnits = [
    "paperless-secret-key.service"
    "paperless-scheduler.service"
    "paperless-task-queue.service"
    "paperless-consumer.service"
    "paperless-web.service"
  ];
in
{
  imports = [
    ./webserver.nix
  ];

  options.services.my.paperless = {
    server = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "paperless.example.org";
      description = "Public Paperless-ngx server name. Empty disables the service.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address Paperless-ngx listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 28981;
      description = "Port Paperless-ngx listens on.";
    };

    domain_crt = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/paperless.example.org/server.crt";
      description = "Path to a pre-existing TLS certificate. Must be set together with domain_key.";
    };

    domain_key = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/paperless.example.org/server.key";
      description = "Path to a pre-existing TLS private key. Must be set together with domain_crt.";
    };

    oidc = {
      issuer = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "id.example.org";
        description = "OIDC issuer URL or hostname. Empty disables OIDC login.";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "Pocket ID";
        description = "Display name of the OIDC login button.";
      };

      providerId = lib.mkOption {
        type = lib.types.str;
        default = "pocket-id";
        description = "allauth provider id, part of the callback URL (/accounts/oidc/<providerId>/login/callback/).";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "paperless";
        description = "OIDC client ID used by Paperless-ngx.";
      };

      # sudo sh -c 'openssl rand -hex 32 | tr -d "\n" > /secrets/paperless/oidc-client-secret'
      clientSecretPath = lib.mkOption {
        type = lib.types.str;
        default = "/secrets/paperless/oidc-client-secret";
        description = "File containing the Paperless-ngx OIDC client secret.";
      };

      adminGroup = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "paperless_admins";
        description = "Pocket ID group claim whose members receive Paperless-ngx superuser privileges.";
      };
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra Paperless-ngx settings merged over the module defaults.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "https://${cfg.server}";
      description = "Derived public Paperless-ngx URL.";
    };
  };

  config = lib.mkIf (cfg.server != "") {
    assertions = [
      {
        assertion = (cfg.domain_crt == null) == (cfg.domain_key == null);
        message = "services.my.paperless.domain_crt and services.my.paperless.domain_key must be set together.";
      }
      {
        assertion = hasDomainCertificate || config.services.my.webserver.acme != null;
        message = "services.my.paperless requires a certificate pair or services.my.webserver.acme to be set.";
      }
    ];

    systemd.tmpfiles.rules = lib.optionals hasDomainCertificate [
      "z ${cfg.domain_crt} 0644 root nginx - -"
      "z ${cfg.domain_key} 0640 root nginx - -"
    ];

    services.paperless = {
      enable = true;
      address = cfg.address;
      port = cfg.port;
      domain = cfg.server;
      environmentFile = lib.mkIf (oidcIssuer != "") oidcEnvFile;

      settings = {
        PAPERLESS_PROXY_SSL_HEADER = [
          "HTTP_X_FORWARDED_PROTO"
          "https"
        ];
      }
      // lib.optionalAttrs (oidcIssuer != "") {
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
        PAPERLESS_DISABLE_REGULAR_LOGIN = true;
        PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;
      }
      // lib.optionalAttrs (oidcIssuer != "" && cfg.oidc.adminGroup != null) {
        PAPERLESS_SOCIAL_ACCOUNT_SYNC_SUPERUSER_GROUP = cfg.oidc.adminGroup;
      }
      // cfg.extraSettings;
    };

    systemd.services.paperless-oidc-env = lib.mkIf (oidcIssuer != "") {
      description = "Paperless OIDC provider configuration";
      before = paperlessUnits;
      requiredBy = paperlessUnits;
      path = [ pkgs.jq ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        providers="$(
          jq -c --rawfile secret ${lib.escapeShellArg cfg.oidc.clientSecretPath} \
            '.openid_connect.APPS[0].secret = ($secret | rtrimstr("\n"))' \
            ${oidcProviders}
        )"
        install -m 0640 -o root -g ${paperlessGroup} /dev/null ${oidcEnvFile}
        printf "PAPERLESS_SOCIALACCOUNT_PROVIDERS='%s'\n" "$providers" > ${oidcEnvFile}
      '';
    };

    services.my.webserver = {
      enable = true;
      virtualHosts.${cfg.server} = {
        locations."/" = {
          proxyPass = "http://${cfg.address}:${toString cfg.port}";
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
    };
  };
}
