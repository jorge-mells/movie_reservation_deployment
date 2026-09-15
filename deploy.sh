#! /usr/bin/env bash
# NOTE: always run locally, otherwise add a terraform backend

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

command="${1:?please provide a command(deploy/configure/cleanup)}"
hcloud_token=$(bw get item 'hcloud_token' | jq -r '.notes')

deploy() {
  printf "\nCreating servers....\n"
  pushd terraform/
  terraform init
  terraform plan -var="hcloud_token=$hcloud_token"
  terraform apply -var="hcloud_token=$hcloud_token"
  popd
}

configure() {
  printf "\nConfiguring servers...\n"

  local user_password

  user_password=$(bw get password '2208acf3-531e-4a13-ba39-b407010b50e1')
  pushd ansible/
  mkdir .ssh
  ansible-playbook -i inventory.yaml playbook.yaml -e "acme_hetzner_auth_token=$hcloud_token ansible_become_pass=$user_password"
  popd
}

cleanup() {
  pushd ansible/
  rm -rf .ssh
  popd

  pushd terraform/
  terraform destroy -var="hcloud_token=$hcloud_token"
  popd
}

"$command"
