#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  # Not exported: this chart's rendered output (embedded dashboard JSON)
  # exceeds the kernel's MAX_ARG_STRLEN (128KiB), which makes any
  # subprocess exec (e.g. yq) fail with E2BIG if RENDERED is in the
  # environment. setup() and the @test body share one bash process, so
  # a plain (unexported) variable is still visible without exporting it.
  RENDERED="$(helm template grafana-test manifests)"
}

@test "anonymous access is enabled" {
  value=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "grafana") |
    .spec.template.spec.containers[0].env[] | select(.name == "GF_AUTH_ANONYMOUS_ENABLED") | .value
  ' -)
  [ "$value" = "true" ]
}

@test "anonymous access org role is Viewer" {
  value=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "grafana") |
    .spec.template.spec.containers[0].env[] | select(.name == "GF_AUTH_ANONYMOUS_ORG_ROLE") | .value
  ' -)
  [ "$value" = "Viewer" ]
}

@test "login form is disabled" {
  value=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "grafana") |
    .spec.template.spec.containers[0].env[] | select(.name == "GF_AUTH_DISABLE_LOGIN_FORM") | .value
  ' -)
  [ "$value" = "true" ]
}
