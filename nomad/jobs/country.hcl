job "country" {
  datacenters = ["dc1"]

  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }

  group "country" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "country-svc" {
      driver = "docker"

      config {
        image = "demo345453/service:cs101"
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
        value     = "worker-1"
      }

      env {
        NOMAD_ENABLE = "true"
        NOMAD_ADDR = "http://${attr.unique.network.ip-address}:4646"
        CONSUL_ENABLE = "true"
        CONSUL_ADDR = "http://${attr.unique.network.ip-address}:8500"
      }

      resources {
        cpu = 300
        memory = 300
        network {
          port "svc" {
            static = 10502
          }
        }
      }

      service {
        name = "country-svc"
        tags = ["country-svc", "urlprefix-country-svc.local/"]
        port = "svc"
        check {
          name     = "country-svc"
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
