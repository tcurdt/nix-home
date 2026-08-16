{
  config,
  lib,
  ...
}:

let
  cfg = config.services.my.oidc;
  hasDomainCertificate = cfg.domain_crt != null && cfg.domain_key != null;
in
{
  options.services.my.oidc = {
    server = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "id.example.org";
      description = "Public Pocket ID / OIDC server name. Empty disables the service.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address Pocket ID listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 1411;
      description = "Port Pocket ID listens on.";
    };

    # sudo sh -c 'openssl rand -hex 32 | tr -d "\n" > /secrets/pocket-id/secret.key'
    encryptionKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/secrets/pocket-id/secret.key";
      description = "File containing the Pocket ID encryption key.";
    };

    databaseConnectionString = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pocket-id/pocket-id.db";
      description = "Pocket ID database connection string.";
    };

    domain_crt = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/id.example.org/server.crt";
      description = "Path to a pre-existing TLS certificate. Must be set together with domain_key.";
    };

    domain_key = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/secrets/certs/id.example.org/server.key";
      description = "Path to a pre-existing TLS private key. Must be set together with domain_crt.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra Pocket ID settings merged over the module defaults.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "https://${cfg.server}";
      description = "Derived public OIDC URL.";
    };
  };

  config = lib.mkIf (cfg.server != "") {
    assertions = [
      {
        assertion = (cfg.domain_crt == null) == (cfg.domain_key == null);
        message = "services.my.oidc.domain_crt and services.my.oidc.domain_key must be set together.";
      }
      {
        assertion = hasDomainCertificate || config.services.my.webserver.acme != null;
        message = "services.my.oidc requires a certificate pair or services.my.webserver.acme to be set.";
      }
    ];

    services.pocket-id = {
      enable = true;

      settings = {
        APP_URL = cfg.url;
        HOST = cfg.address;
        PORT = cfg.port;
        TRUST_PROXY = true;
        ALLOW_OWN_ACCOUNT_EDIT = false;
        DB_CONNECTION_STRING = cfg.databaseConnectionString;
        VERSION_CHECK_DISABLED = true;
        ANALYTICS_DISABLED = true;
        ENCRYPTION_KEY_FILE = cfg.encryptionKeyFile;
      }
      // cfg.extraSettings;
    };

    services.my.webserver.virtualHosts.${cfg.server} = {
      locations."/" = {
        proxyPass = "http://${cfg.address}:${toString cfg.port}";
        extraConfig = ''
          proxy_busy_buffers_size 512k;
          proxy_buffers 4 512k;
          proxy_buffer_size 256k;
        '';
      };
    }
    // lib.optionalAttrs hasDomainCertificate {
      enableACME = false;
      sslCertificate = cfg.domain_crt;
      sslCertificateKey = cfg.domain_key;
    };

  };
}
