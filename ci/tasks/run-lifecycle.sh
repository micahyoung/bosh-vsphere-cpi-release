#! /bin/bash

set -e

source bosh-cpi-src/ci/utils.sh
source bosh-cpi-src/.envrc

# Required to run and spawn nimbus testbed
sudo apt-get -y update
sudo apt-get -y install jq rsync ssh

# Spawn the test environment on nimbus
pushd vcpi-nimbus
  echo "$DBC_SSH_KEY" > ./dbc_ssh_key
  chmod 400 dbc_ssh_key
  ./launch -s 'ssh -i dbc_ssh_key -o StrictHostKeyChecking=no'
  source environment.sh
popd

export HTTP_PROXY="http://$BOSH_VSPHERE_JUMPER_HOST:3128"

if [ -f /etc/profile.d/chruby.sh ]; then
  source /etc/profile.d/chruby.sh
  chruby $PROJECT_RUBY_VERSION
fi

: ${RSPEC_FLAGS:=""}
: ${BOSH_VSPHERE_STEMCELL:=""}

# allow user to pass paths to spec files relative to src/vsphere_cpi
# e.g. ./run-lifecycle.sh spec/integration/core_spec.rb
if [ "$#" -ne 0 ]; then
  RSPEC_ARGS="$@"
fi

if [ -z "${BOSH_VSPHERE_STEMCELL}" ]; then
  stemcell_dir="$( cd stemcell && pwd )"
  export BOSH_VSPHERE_STEMCELL=${stemcell_dir}/stemcell.tgz
fi

install_iso9660wrap() {
  pushd bosh-cpi-src
    pushd src/iso9660wrap
      go build ./...
      export PATH="$PATH:$PWD"
    popd
  popd
}

install_iso9660wrap

pushd bosh-cpi-src/src/vsphere_cpi
  bundle install
  bundle exec rspec ${RSPEC_FLAGS} --require ./spec/support/verbose_formatter.rb --format VerboseFormatter spec/integration
popd
