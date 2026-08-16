{
  # pkgs,
  ...
}:
{

  networking.hostName = "home-ber";
  networking.domain = "home";
  system.stateVersion = "23.11";

  imports = [

    ../hardware/lenovo.nix

    ../modules/server.nix
    ../modules/users.nix

    ../users/root.nix
    ../users/tcurdt.nix

    { users.users.root.password = "secret"; }

    ../modules/webserver.nix
    ../modules/oidc.nix
    ../modules/forgejo.nix
  ];

  services.my.webserver = {
    enable = true;
    # acme = "email@example.com";
  };

  # sudo sh -c 'openssl rand -hex 32 | tr -d "\n" > /secrets/pocket-id.key'
  # open https://id.home/setup
  services.my.oidc = {
    server = "id.home";
    domain_crt = "/secrets/certs/id.home/server.crt";
    domain_key = "/secrets/certs/id.home/server.key";
  };

  services.my.forgejo = {
    server = "git.home";
    domain_crt = "/secrets/certs/git.home/server.crt";
    domain_key = "/secrets/certs/git.home/server.key";
    oidc = {
      issuer = "id.home";
    };
  };

}
