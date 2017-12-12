#! /bin/bash

set -e

source bosh-cpi-src/ci/utils.sh
source bosh-cpi-src/.envrc
bosh-cpi-src/dev-utils.sh

# Source the test environment variables
pushd vcpi-nimbus
  source environment.sh
popd

stemcell_dir="$HOME/stemcell"
export BOSH_VSPHERE_STEMCELL=${stemcell_dir}/stemcell.tgz

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

install_iso9660wrap() {
  pushd bosh-cpi-src
    pushd src/iso9660wrap
      /usr/local/go/bin/go build ./...
      export PATH="$PATH:$PWD"
    popd
  popd
}

install_iso9660wrap

pushd bosh-cpi-src/src/vsphere_cpi
  bundle install
  bundle exec rspec ${RSPEC_FLAGS} --require ./spec/support/verbose_formatter.rb --format VerboseFormatter spec/integration
popd
