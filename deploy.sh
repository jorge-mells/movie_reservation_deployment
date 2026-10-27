#! /usr/bin/env bash
# NOTE: always run locally, otherwise add a terraform backend

set -euo pipefail
trap "echo 'error: Script failed: see failed command'" ERR

command="${1:?please provide a command(provision/configure/cleanup)}"

provision() {
  printf "\nCreating servers....\n"
  pushd terraform/
  terraform init
  terraform plan
  terraform apply
  popd

}

configure() {
  printf "\nConfiguring servers...\n"
  pushd ansible-new/
  ansible-galaxy install -r requirements.yml
  ansible-playbook site.yml
  popd
}

cleanup() {
  # FIX: make an ansible playbook which does this cleanup better.
  truncate -s 0 ~/.ssh/virtual_known_hosts
  pushd ansible-new/
  ansible-playbook cleanup.yml
  popd
  pushd terraform/
  terraform destroy
  popd
}

"$command"
