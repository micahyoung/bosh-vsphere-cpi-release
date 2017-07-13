#!/usr/bin/env bash

ruby_vim_sdk_path="${SRC_DIR}/lib/ruby_vim_sdk"

version_tag=$1
: ${version_tag:=?}
vmware_pyvmimu_url="https://raw.githubusercontent.com/vmware/pyvmomi"
files_to_download="{ServerObjects.py,CoreTypes.py}"

curl --remote-name "${vmware_pyvmimu_url}/${version_tag}/pyVmomi/${files_to_download}"

./gen_server_objects.py > "${ruby_vim_sdk_path}/server_objects.rb"
./gen_core_types.py > "${ruby_vim_sdk_path}/core_types.rb"
