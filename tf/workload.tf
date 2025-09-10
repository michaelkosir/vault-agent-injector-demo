resource "kubernetes_namespace" "workload" {
  depends_on = [kind_cluster.dev]

  metadata {
    name = var.workload_namespace
  }
}

resource "kubernetes_service_account" "workload" {
  metadata {
    name      = var.workload_name
    namespace = kubernetes_namespace.workload.metadata[0].name
  }
}

resource "kubernetes_deployment" "workload" {
  depends_on = [helm_release.vai, vault_database_secret_backend_role.postgres]

  metadata {
    name      = var.workload_name
    namespace = kubernetes_namespace.workload.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.workload_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.workload_name
        }

        annotations = {
          # Inject the Vault Agent sidecar
          "vault.hashicorp.com/agent-inject" = "true"
          "vault.hashicorp.com/auth-path"    = "auth/k8s"
          "vault.hashicorp.com/role"         = var.workload_role

          # KV (static) credentials
          "vault.hashicorp.com/agent-inject-secret-app"   = "kv/path/to/secret"
          "vault.hashicorp.com/agent-inject-template-app" = <<-EOF
          {{- with secret "kv/path/to/secret" -}}
          hello={{ .Data.data.hello}}
          foo={{ .Data.data.foo}}
          ping={{ .Data.data.ping}}
          fizz={{ .Data.data.fizz}}
          api={{ .Data.data.api}}
          {{- end }}
          EOF

          # Postgres database credentials
          "vault.hashicorp.com/agent-inject-secret-database"   = "postgres/creds/example"
          "vault.hashicorp.com/agent-inject-template-database" = <<-EOF
          {{- with secret "postgres/creds/example" -}}
          username={{ .Data.username }}
          password={{ .Data.password }}
          {{- end }}
          EOF
        }
      }

      spec {
        service_account_name = kubernetes_service_account.workload.metadata[0].name

        volume {
          name = "vault-service-account-token"
          projected {
            sources {
              service_account_token {
                path               = "token"
                audience           = "vault"
                expiration_seconds = 60 * 10 # 10 min
              }
            }
          }
        }

        container {
          name    = "app"
          image   = "alpine:latest"
          command = ["/bin/sh", "-c"]
          args    = ["while true; do for f in /vault/secrets/*; do echo \"$(date +%T) $f\"; cat \"$f\"; echo; echo; done && sleep 10; done"]

          volume_mount {
            name       = "vault-service-account-token"
            mount_path = "/var/run/secrets/vault.hashicorp.com/serviceaccount"
            read_only  = true
          }
        }
      }
    }
  }
}
