# Nextcloud — runs as a **podman AIO container**, NOT the nixpkgs module.
# 2026-08-12 ruling: nixpkgs Nextcloud is 2 majors behind (32 vs 34) and cannot
# run EuroOffice/Memories/Passwords (they only exist as AIO containers).
# Declared via virtualisation.oci-containers.backend = "podman".
#
# This file is the BUILD TARGET — the builder turns it into the actual
# oci-containers declaration (pinned images, sops env). Until built, the docs
# in OpenCode.md §Cloud are authoritative.
{ config, lib, pkgs, settings, users, ... }:
let
  helpers = import ../networking/nginx-helpers.nix { inherit lib settings users; };
in
{
  # TODO(build): declare Nextcloud AIO as podman containers:
  #   virtualisation.oci-containers.backend = "podman";
  #   virtualisation.oci-containers.containers.nextcloud-aio = {
  #     image = "ghcr.io/nextcloud-releases/all-in-one:v13.4.1";  # pinned
  #     environmentFiles = [ config.sops.secrets.nextcloud_aio_env.path ];
  #     volumes = [ "/fast/users:/mnt/users" ... ];
  #     ports = [ "127.0.0.1:8080:80" ];  # loopback -> nginx ingress
  #   };
  # Sub-containers managed by AIO: postgres, redis, apache, eurooffice.

  services.nginx.virtualHosts."cloud.${settings.domains.internal}" = {
    forceSSL = true;
    useACMEHost = settings.domains.internal;
    extraConfig = helpers.userAllowlist;
  };
}
