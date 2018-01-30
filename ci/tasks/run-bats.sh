#!/usr/bin/env bash


: ${STEMCELL_NAME:?}
: ${BAT_RSPEC_FLAGS:?}


mkdir -p bats-config

bosh int bosh-cpi-src/ci/bats-spec.yml \
  -v "stemcell_name=${STEMCELL_NAME}" \
  -v "network1-staticIP-2=" \
  -v "network1-staticIP-1=" \
  -v "network1-vCenterCIDR=" \
  -v "network1-staticRange=" \
  -v "network1-reservedRange=" \
  -v "network1-vCenterGateway=" \
  -v "network1-vCenterVLAN=" \
  -v "network2-staticIP-1=" \
  -v "network2-vCenterCIDR=" \
  -v "network2-reservedRange=" \
  -v "network2-staticRange=" \
  -v "network2-vCenterGateway=" \
  -v "network2-vCenterVLAN=" > bats-config/bats-config.yml

source director-state/director.env
export BAT_PRIVATE_KEY="$(bosh int director-state/creds.yml --path=/jumpbox_ssh/private_key)"
export BAT_DNS_HOST="${BOSH_ENVIRONMENT}"
export BAT_STEMCELL=$(realpath stemcell/*.tgz)
export BAT_DEPLOYMENT_SPEC=$(realpath bats-config/bats-config.yml)
export BAT_BOSH_CLI=$(which bosh)

ssh_key_path=/tmp/bat_private_key
echo "$BAT_PRIVATE_KEY" > $ssh_key_path
chmod 600 $ssh_key_path
export BOSH_GW_PRIVATE_KEY=$ssh_key_path

pushd bats
  bundle install
  bundle exec rspec spec $BAT_RSPEC_FLAGS
popd