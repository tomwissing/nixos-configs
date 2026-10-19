let
  tom-wsl = builtins.readFile ./ssh/users/tom-wsl.pub;
  tom-win = builtins.readFile ./ssh/users/tom-win.pub;
  tom-zorn = builtins.readFile ./ssh/users/tom-zorn.pub;
  tom-iphone17 = builtins.readFile ./ssh/users/tom-iphone17.pub;
  tom-msi = builtins.readFile ./ssh/users/tom-msi.pub;
  tom = [ tom-wsl tom-win tom-zorn tom-msi ];

  rpi3 = builtins.readFile ./ssh/hosts/rpi3.pub;
  msi = builtins.readFile ./ssh/hosts/msi-thin-gf63-12vf.pub;
  systems = [ rpi3 msi ];
in
{
  "miniflux.age".publicKeys = systems ++ tom;
  "cloudflare-dns.age".publicKeys = systems ++ tom;
  "acme-email.age".publicKeys = systems ++ tom;
  "rpi3-wireguard-pr.age".publicKeys = systems ++ tom;
  "rpi3-wireguard-sh.age".publicKeys = systems ++ tom;
  "vaultwarden.age".publicKeys = systems ++ tom;
}