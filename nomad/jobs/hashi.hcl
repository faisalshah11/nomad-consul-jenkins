job "hashi-ui" {
  datacenters = ["dc1"]

  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }

  group "hashi-ui" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "hashi-ui" {
      driver = "docker"

      config {
        dns_servers = ["${attr.unique.network.ip-address}"]
        dns_options = ["use-vc"]
        image = "jippi/hashi-ui:v0.22.0"
        force_pull = false
        port_map {
          hashi_ui = 3000
        }
      }

      constraint {
        attribute = "${meta.exclusive}"
        operator  = "="
        value     = "fabio-lb"
      }

      env {
        NOMAD_ENABLE = "true"
        NOMAD_ADDR = "http://${attr.unique.network.ip-address}:4646"
        CONSUL_ENABLE = "true"
        CONSUL_ADDR = "http://${attr.unique.network.ip-address}:8500"
      }

      resources {
        cpu    = 250
        memory = 128
        network {
          port "hashi_ui" {}
        }
      }

      service {
        name = "hashi-ui"
        tags = ["hashi-ui", "urlprefix-hashi-ui.local/"]
        port = "hashi_ui"
        check {
          name     = "hashi-ui"
          type     = "http"
          interval = "5s"
          timeout  = "2s"
          path     = "/_status"

          check_restart {
            limit = 3
            grace = "30s"
          }
        }
      }

    }
  }
}
