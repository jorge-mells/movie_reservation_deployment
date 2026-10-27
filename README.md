## Ansible
- make sure to encrypt your secrets.yaml before committing!!(use pre-commit) after creating from secrets.yaml
- make sure to create credentials/webhook_secret.txt like
`mkdir -p credentials
openssl rand -hex 32 > credentials/webhook_secret.txt`
- make sure to add a .vault_pass(use pre-commits to ci check this and add some sort of setup script)

# NOTES
- this would probably not work on ubuntu(i.e: only podman works)
