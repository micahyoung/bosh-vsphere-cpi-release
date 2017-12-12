#! /bin/bash

set -e

source bosh-cpi-src/ci/utils.sh
source bosh-cpi-src/.envrc

# Required to run and spawn nimbus testbed
sudo apt-get -y update
sudo apt-get -y install jq
sudo apt-get -y install openvpn
sudo apt-get -y install openssh-client
sudo apt-get -y install rsync
sudo apt-get -y install sshpass


# Spawn the test environment on nimbus
pushd vcpi-nimbus
  echo "$DBC_KEY" > ./dbc_key
  chmod 400 dbc_key
  #./launch -i dbc_key
  source environment.sh
popd

export JUMPBOX_PASSWORD='vcpi'
export JUMPBOX_REMOTE="vcpi@$BOSH_VSPHERE_JUMPER_HOST"
export JUMPBOX_BUILD_DIR='~'
export PARENT_DIR="$PWD"

echo $JUMPBOX_PASSWORD
echo $JUMPBOX_REMOTE
echo $JUMPBOX_BUILD_DIR
echo $PARENT_DIR

pushd vcpi-nimbus
  echo "export RSPEC_FLAGS=\"$RSPEC_FLAGS\"" >> environment.sh
popd

# Ensure tmpdir and control socket are cleaned up on exit
master_exit() {
  sshpass -p $JUMPBOX_PASSWORD ssh -o "StrictHostKeyChecking no" -O exit -S "$tmpdir/master.sock" $remote &> /dev/null
  rm -rf "$tmpdir"
}
trap master_exit EXIT

tmpdir="$(mktemp -dt master 2> /dev/null || mktemp -dt master.XXXX)"
sshpass -p $JUMPBOX_PASSWORD ssh -MNfS "$tmpdir/master.sock" -o "StrictHostKeyChecking no" -o ControlPersist=0 $JUMPBOX_REMOTE
sshpass -p $JUMPBOX_PASSWORD rsync -ave "ssh -S '$tmpdir/master.sock'" \
  "$PARENT_DIR/" \
  $JUMPBOX_REMOTE:$JUMPBOX_BUILD_DIR

sshpass -p $JUMPBOX_PASSWORD ssh $JUMPBOX_REMOTE 'chmod +x ~/bosh-cpi-src/ci/vmware/tasks/run-test.sh'
sshpass -p $JUMPBOX_PASSWORD ssh $JUMPBOX_REMOTE '~/bosh-cpi-src/ci/vmware/tasks/run-test.sh'
