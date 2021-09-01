resource "google_game_services_game_server_cluster" "default" {

  cluster_id = "${var.cluster_name}-gcgs-cluster"
  realm_id   = google_game_services_realm.default.realm_id

  connection_info {
    gke_cluster_reference {
      cluster = "locations/${var.region}/clusters/${var.cluster_name}"
    }
    namespace = "default"
  }
}

resource "google_game_services_realm" "default" {
  realm_id  = "${var.cluster_name}-realm"
  time_zone = "EST"
  location  = var.region
  description = "realm for supertuxkart"
}

resource "google_game_services_game_server_deployment" "default" {
  deployment_id  = "${var.cluster_name}-deployment"
  description = "deployment for supertuxkart"
}

resource "google_game_services_game_server_config" "default" {
  config_id     = "${var.cluster_name}-config"
  deployment_id = google_game_services_game_server_deployment.default.deployment_id
  description   = "a config description"

    fleet_configs {
        name       = "supertuxkart-fleet"
        fleet_spec = jsonencode(yamldecode(file("fleet_configs.yaml")))
    }

    # scaling_configs {
    #     name = "supertuxkart-scaling-config"
    #     fleet_autoscaler_spec = jsonencode(yamldecode(file("scaling_configs.yaml")))
    # }
}

resource "google_game_services_game_server_deployment_rollout" "default" {
  deployment_id              = google_game_services_game_server_deployment.default.deployment_id
  default_game_server_config = google_game_services_game_server_config.default.name
}