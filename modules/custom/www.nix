{ moduleWithSystem, ... }:
{
  # Configuration for http virtual hosts.
  flake.nixosModules.www = moduleWithSystem (
    { pkgs, ... }:
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.tilde.www;

      ##############################################################################
      # Return virtual hosts sorted in a way where the default host comes first.
      sortedHosts =
        let
          hosts = cfg.sites ++ map forwardToVHost cfg.forwards;
          default = builtins.filter (h: cfg.defaultHost == h.name) hosts;
          others = builtins.filter (h: cfg.defaultHost != h.name) hosts;
        in
        default ++ others;

      ##############################################################################
      # Convert a forward configuration into a virtual host.
      forwardToVHost = f: {
        inherit (f) name;
        inherit (f.vhost)
          subdomain
          aliases
          documentRoot
          allowedIPs
          ;
        extraConfig = ''
          ${f.vhost.extraConfig}
          RequestHeader set X-Real-IP %{REMOTE_ADDR}s
          RequestHeader set X_FORWARDED_PROTO 'https'
          ProxyPreserveHost On

          # Don't proxy requests for /.well-known/acme-challenge/...
          ProxyPass /.well-known !

          # Allow httpd to access its own error file without trying to
          # proxy it.
          ProxyPass /error !

          ${lib.optionalString (lib.hasPrefix "https" f.to) "SSLProxyEngine on"}
          ProxyPass / ${f.to}/ upgrade=websocket
        '';
      };

      ##############################################################################
      # Return the document root for a virtual host.
      hostDir = host: "${cfg.baseDir}/${host.name}/current";

      ############################################################################
      # Simple subdomains that proxy to a locally running service:
      forwardOpts = {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            example = "devalot.com";
            description = "Hostname for this virtual host.";
          };

          to = lib.mkOption {
            type = lib.types.str;
            example = "http://127.0.0.1:3000/";
            description = "URL to proxy requests to.";
          };

          vhost = lib.mkOption {
            type = lib.types.submodule virtualHost;
            default = { };
            description = "Pass on extra information to the virtual host.";
          };
        };
      };

      ############################################################################
      # Configuration options for a single virtual hosts.
      virtualHost = {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            example = "devalot.com";
            description = "Hostname for this virtual host.";
          };

          aliases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "ftp.devalot.com" ];
            description = "Other names for this host.";
          };

          documentRoot = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Normally you will want to leave this set to null and use the
              default.  But, if you want to use something other than the
              default you can set this manually.
            '';
          };

          allowedIPs = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = ''
              List of IP addresses with masks that are allowed to access
              this virtual host.'';
          };

          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            example = "";
            description = "Extra Apache configuration.";
          };
        };
      };

      # A function which takes a virtualHost configuration from above
      # and turns it into an Apache VirtualHost configuration.
      toApacheVHost =
        host:
        let
          docRoot = if host.documentRoot == null then hostDir host else host.documentRoot;
        in
        {
          name = host.name;
          value = {
            serverAliases = host.aliases;
            adminAddr = cfg.adminEmail;
            documentRoot = docRoot;
            logFormat = cfg.logFormat;
            forceSSL = true;
            enableACME = host.name == cfg.defaultHost;
            useACMEHost = if host.name == cfg.defaultHost then null else cfg.defaultHost;
            acmeRoot =
              if config.security.acme.defaults.dnsProvider != null then null else "/var/lib/acme/acme-challenge";

            extraConfig = ''
              # Enable the rewrite engine.
              RewriteEngine On

              <Directory "${docRoot}">
                # Turn off directory indexes.
                Options -Indexes

                # Fix ETags in /nix/store
                FileETag INode Size
              </Directory>

              # Default redirection to the canonical name of the site:
              RewriteCond %{HTTPS} on
              RewriteCond %{HTTP_HOST} !=${host.name} [NC]
              RewriteRule (.*) https://${host.name}%{REQUEST_URI} [R=301,L,QSA]

              # If the request doesn't have ".html" and adding that extension
              # results in a valid file, tack it on automatically.
              RewriteCond %{REQUEST_METHOD} ^(GET|HEAD)$
              RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI}.html -f
              RewriteRule ^(.+)$ $1.html [L,PT]

              # Serve pre-gzipped versions of files.
              RewriteCond %{REQUEST_FILENAME}.gz -s
              RewriteRule ^(.+)$ $1.gz [L,PT]

              # Without this, Content-Type will be "application/x-gzip"
              <FilesMatch .*\.css\.gz>
                ForceType text/css
              </FilesMatch>

              <FilesMatch .*\.js\.gz>
                ForceType text/javascript
              </FilesMatch>
            ''
            + lib.optionalString (builtins.length host.allowedIPs > 0) ''
              <Directory "${docRoot}">
                Require ip ${lib.concatStringsSep " " host.allowedIPs}
              </Directory>
              <Location "/">
                Require ip ${lib.concatStringsSep " " host.allowedIPs}
              </Location>
            ''
            + host.extraConfig;
          };
        };

      ##############################################################################
      # A script to run just before Apache starts that will create all the
      # necessary directories.
      beforeApache =
        let
          path = lib.makeBinPath [ pkgs.coreutils ];
          mkdirs = lib.concatMapStringsSep "\n" (dir: "mkdir -p ${dir}") (map hostDir sortedHosts);
        in
        pkgs.writeShellScript "webmaster.sh" ''
          set -e
          set -u

          export PATH=${path}:$PATH

          mkdir -p ${cfg.baseDir}
          mkdir -p ${cfg.logBackupDir}
          ${mkdirs}

          chown -R ${cfg.user}:${cfg.group} ${cfg.baseDir}
          chmod -R u=rwX,go=rX ${cfg.baseDir}
        '';
    in
    {
      options.tilde.www = {
        sites = lib.mkOption {
          type = with lib.types; listOf (submodule virtualHost);
          default = [ ];
        };

        forwards = lib.mkOption {
          type = with lib.types; listOf (submodule forwardOpts);
          default = [ ];
          description = "List of forward configs (reverse proxies).";
        };

        baseDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/websites";
          example = "/var/lib/websites";
          description = "Document roots for all websites.";
        };

        defaultHost = lib.mkOption {
          type = lib.types.str;
          example = "devalot.com";
          description = ''
            Which host to make the first Virtual host and the primary
            TLS certificate host.
          '';
        };

        adminEmail = lib.mkOption {
          type = lib.types.str;
          default = "domains@${config.networking.domain}";
          example = "domains@example.com";
          description = "Email address for site administrator.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "webmaster";
          description = "User who owns the document root.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "webmaster";
          description = "Group for the document root.";
        };

        logFormat = lib.mkOption {
          type = lib.types.str;
          default = "combined";
          description = "Apache log format.";
        };

        logBackupDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/backup/httpd";
          description = "Directory where rotated log files go.";
        };
      };

      config = lib.mkIf (builtins.length sortedHosts > 0) {
        assertions = [
          {
            assertion = config.networking.domain != null;
            message = "virtualhosts service requires networking.domain to be set";
          }
        ];

        # Make sure the firewall is open for business:
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        # Basic Apache configuration for the host.
        services.httpd = {
          enable = true;
          adminAddr = cfg.adminEmail;
          logFormat = cfg.logFormat;
          logPerVirtualHost = true;
          extraModules = [ "deflate" ];
          virtualHosts = builtins.listToAttrs (map toApacheVHost sortedHosts);
        };

        security.acme.certs.${cfg.defaultHost}.extraDomainNames = map (host: host.name) (
          builtins.filter (host: host.name != cfg.defaultHost) sortedHosts
        );

        # Users needed for the webmaster:
        users.groups.${cfg.group} = {
          members = [ "wwwrun" ];
        };

        users.users.${cfg.user} = {
          name = cfg.user;
          group = cfg.group;
          description = "Webmaster";
          isNormalUser = true;
          home = "${cfg.baseDir}";
          createHome = lib.mkForce false; # Don't set home permissions!
          useDefaultShell = true;
        };

        systemd.services.webmaster-setup = {
          description = "Webmaster Setup";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.service" ];

          serviceConfig = {
            ExecStart = toString beforeApache;
            Type = "oneshot";
            RemainAfterExit = true;
            UMask = "0077";
          };
        };

        systemd.services.httpd.after = [ "webmaster-setup.service" ];
      };
    }
  );
}
