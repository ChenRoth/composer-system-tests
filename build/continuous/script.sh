#!/usr/bin/env bash

set -e

echo "build started"

export VAGRANT_BASEDIR="`pwd`/build/continuous" # contains provision script and synced folder
export VAGRANT_WORKDIR="${VAGRANT_BASEDIR}/aws" # contains the Vagrantfile itself


echoerr() { echo "$@" 1>&2; }

echo "user is $USER";

echo "installing node"
nvm install 0.10.35 # keep this in older version deliberately.

which json || npm install -g json
echo "GIT_REFERENCE is ${GIT_REFERENCE}"
chmod 600 ${CONFIG_FILE}
json -I -f ${CONFIG_FILE} -e "this.environmentVariables.GIT_REFERENCE=\"${GIT_REFERENCE}\""
json -I -f ${CONFIG_FILE} -e "this.environmentVariables.TEST_TYPE=\"${TEST_TYPE}\""
json -I -f ${CONFIG_FILE} -e "this.environmentVariables.BROWSER_TYPE=\"${BROWSER_TYPE}\""


ls -ll ${CONFIG_FILE}

# replace json file placeholders with environment variables. https://github.com/guy-mograbi-at-gigaspaces/node-replace-env-in-json-file
curl -L https://raw.githubusercontent.com/cloudify-cosmo/node-replace-env-in-json-file/master/inject.js | INJECT_FILE="${CONFIG_FILE}" node

chmod 600  ${PEM_FILE}


which vagrant-automation-machines-copy || npm install cloudify-cosmo/vagrant-automation-machines -g

function cleanup(){
    pushd ${VAGRANT_WORKDIR}
        echo "I am at `pwd` and I am destroying the machine"
        vagrant destroy -f
    popd
}
trap cleanup EXIT

pushd ${VAGRANT_BASEDIR}
    vagrant-automation-machines-setup aws
    cleanup || echo "no need to teardown the machine because it was not running"
    pushd ${VAGRANT_WORKDIR}
        vagrant up --provider=aws
    popd
popd

#pushd ${REPORTS_BASEDIR}
#    rm -rf reports
#    vagrant-automation-machines-copy reports # copy from guest machine!
#popd

