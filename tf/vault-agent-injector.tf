resource "helm_release" "vai" {
  depends_on = [kind_cluster.dev, kubernetes_pod.vault]

  name             = "vault-agent-injector"
  namespace        = "vault-agent-injector"
  create_namespace = true

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.vai_version

  set {
    name  = "global.externalVaultAddr"
    value = "http://vault.vault.svc.cluster.local"
  }

  set {
    name  = "server.enabled"
    value = false
  }
}
