{ config, lib, pkgs, ... }:
with lib;
let
  wazuhUser = "wazuh";
  wazuhGroup = wazuhUser;
  stateDir = "/var/ossec";
  cfg = config.services.wazuh;
  pkg = pkgs.wazuh;
in {
  options = {
    services.wazuh = {
      agent = {
        enable = mkEnableOption "Wazuh agent";

        managerIP = mkOption {
          types = types.str;
          description = ''
            The IP address or hostname of the manager. This is a required value.
          '';
          example = "192.168.1.2";
        };

        managerPort = mkOption {
          types = types.int;
          description = ''
            The port the manager is listening on to receive agent traffic.
          '';
          example = 1514;
          default = 1514;
        };
      };
    };
  };

  config = mkIf ( cfg.agent.enable ) {
    assert assertMsg ( cfg.agent.managerIP != "" ) "services.wazuh.agent.managerIP must be set"; "";

    # Generate and write the agent config using the options supplied.
    # This gets written to the store, but will be moved to /var/ossec/etc/ later.
    writeTextFile "etc/ossec.conf" import ./generate-agent-config.nix { cfg };

    environment.systemPackages = [ pkg ];

    users.users.${ wazuhUser } = {
      uid = config.ids.uids.wazuh;
      group = wazuhGroup;
      description = "Wazuh daemon user";
      home = stateDir;
    };

    users.groups.${ wazuhGroup } = {
      gid = config.ids.gids.wazuh;
    };

    systemd.services.wazuh-agent = mkIf cfg.agent.enable {
      path = [
        pkgs.busybox
      ];
      description = "Wazuh agent";
      wants = [ "network-online.target" ];
      after = [ "network.target" "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -m 0750 -p ${stateDir}
        cp -rf ${pkg}/* ${stateDir}

        find ${stateDir} -type f -exec chmod 644 {} \;
        find ${stateDir} -type d -exec chmod 750 {} \;
        chmod u+x ${stateDir}/bin/*
        chmod u+x ${stateDir}/active-response/bin/*
        chown -R ${wazuhUser}:${wazuhGroup} ${stateDir}
      '';

      serviceConfig = {
        Type = "forking";
        WorkingDirectory = stateDir;
        ExecStart = "${stateDir}/bin/wazuh-control start";
        ExecStop = "${stateDir}/bin/wazuh-control stop";
        ExecReload = "${stateDir}/bin/wazuh-control reload";
        KillMode = "process";
        RemainAfterExit = "yes";
      };
    };
  };
}