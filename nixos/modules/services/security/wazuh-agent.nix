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

        # TODO: mkOption -> XML for ossec.conf
      };
    };
  };

  config = mkIf ( cfg.agent.enable ) {
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
        WorkingDirectory = ${stateDir}
        ExecStart = "env ${pkg}/bin/wazuh-control start";
        ExecStop = "env ${pkg}/bin/wazuh-control stop";
        ExecReload = "env ${pkg}/bin/wazuh-control reload";
        KillMode = "process";
        RemainAfterExit = "yes";
      };
    };
  };
}