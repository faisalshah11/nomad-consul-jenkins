job "airport" {
  datacenters = ["dc1"]

  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }

  group "airport" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "airport-svc" {
      driver = "docker"

      config {
        image = "demo345453/service:version"
#        auth {
#            username = "XXXXXXXXX"
#            password = "XXXXXXXXX"
#        }
        force_pull = false
        port_map {
          svc = 8080
        }
      }

      constraint {
        attribute = "${meta.exclusive}"
        operator  = "="
        value     = "worker-2"
      }

      env {
        NOMAD_ENABLE = "true"
        NOMAD_ADDR = "http://${attr.unique.network.ip-address}:4646"
        CONSUL_ENABLE = "true"
        CONSUL_ADDR = "http://${attr.unique.network.ip-address}:8500"
      }

      resources {
        cpu = 6000
        memory = 900
        network {
          port "svc" {
            static = 10501
          }
        }
      }

      service {
        name = "airport-svc"
        tags = ["airport-svc", "urlprefix-airport-svc.local/"]
        port = "svc"
        check {
          name     = "airport-svc"
          type     = "http"
          interval = "60s"
          timeout  = "120s"
          path     = "/health/ready"

          check_restart {
            limit = 3
            grace = "30s"
          }
        }
      }

    }
  }
}
