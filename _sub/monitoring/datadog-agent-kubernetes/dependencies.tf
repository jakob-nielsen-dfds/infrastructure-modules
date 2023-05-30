data "github_repository" "main" {
  full_name = "${var.github_owner}/${var.repo_name}"
}

locals {
  default_repo_branch = data.github_repository.main.default_branch
  repo_branch         = length(var.repo_branch) > 0 ? var.repo_branch : local.default_repo_branch
  cluster_repo_path   = "clusters/${var.cluster_name}"
  helm_repo_path      = "platform-apps/${var.cluster_name}/${var.deploy_name}/helm"
  config_repo_path    = "platform-apps/${var.cluster_name}/${var.deploy_name}/config"
  app_install_name    = "platform-apps-${var.deploy_name}"

  app_helm_path = {
    "apiVersion" = "kustomize.toolkit.fluxcd.io/v1beta2"
    "kind"       = "Kustomization"
    "metadata" = {
      "name"      = "${local.app_install_name}-helm"
      "namespace" = "flux-system"
    }
    "spec" = {
      "interval" = "1m0s"
      "dependsOn" = [
        {
          "name" = "platform-apps-sources"
        }
      ]
      "sourceRef" = {
        "kind" = "GitRepository"
        "name" = "flux-system"
      }
      "path"  = "./${local.helm_repo_path}"
      "prune" = true
    }
  }

  app_config_path = {
    "apiVersion" = "kustomize.toolkit.fluxcd.io/v1beta2"
    "kind"       = "Kustomization"
    "metadata" = {
      "name"      = "${local.app_install_name}-config"
      "namespace" = "flux-system"
    }
    "spec" = {
      "interval" = "1m0s"
      "dependsOn" = [
        {
          "name" = "${local.app_install_name}-helm"
        }
      ]
      "sourceRef" = {
        "kind" = "GitRepository"
        "name" = "flux-system"
      }
      "path"  = "./${local.config_repo_path}"
      "prune" = true
    }
  }

  helm_install = {
    "apiVersion" = "kustomize.config.k8s.io/v1beta1"
    "kind"       = "Kustomization"
    "resources" = [
      "${var.gitops_apps_repo_url}/apps/${var.deploy_name}?ref=${var.gitops_apps_repo_branch}"
    ]
    "patchesStrategicMerge" = [
      "patch.yaml"
    ]
  }

  helm_patch = {
    "apiVersion" = "helm.toolkit.fluxcd.io/v2beta1"
    "kind"       = "HelmRelease"
    "metadata" = {
      "name"      = "datadog-operator"
      "namespace" = var.namespace
    }
    "spec" = {
      "chart" = {
        "spec" = {
          "version" = var.helm_chart_version
        }
      }
    }
  }

  config_init = {
    "apiVersion" = "kustomize.config.k8s.io/v1beta1"
    "kind"       = "Kustomization"
    "resources" = [
      "agent.yaml"
    ]
  }

    config_agent = <<YAML
apiVersion: datadoghq.com/v2alpha1
kind: DatadogAgent
metadata:
  name: datadog
  namespace: ${var.namespace}
spec:
  global:
    clusterName: ${var.cluster_name}
    credentials:
      apiSecret:
        secretName: ${var.api_secret_name}
        keyName: ${var.api_secret_key}
      appSecret:
        secretName: ${var.app_secret_name}
        keyName: ${var.app_secret_key}
    site: ${var.site}
  override:
    nodeAgent:
%{ if length(var.tolerations) > 0 ~}
      tolerations:
%{ for t in var.tolerations ~}
      - key: ${t.key}
        operator: ${t.operator}
%{ if t.value != null ~}
        value: ${t.value}
%{ endif ~}
        effect: ${t.effect}
%{ endfor ~}
%{ endif ~}
  features:
    apm:
      enabled: true
    logCollection:
      enabled: true
      containerCollectAll: true
    eventCollection:
      collectKubernetesEvents: true
    liveProcessCollection:
      enabled: true
    liveContainerCollection:
      enabled: true
    admissionController:
      enabled: false
    externalMetricsServer:
      enabled: false
      useDatadogMetrics: false
    clusterChecks:
      enabled: true
    npm:
      enabled: true
    usm:
      enabled: true
  YAML

}