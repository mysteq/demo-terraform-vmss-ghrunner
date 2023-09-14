#!/bin/sh

if [ "`whoami`" != "runasuser" ]; then
  useradd -m runasuser
  sudo -u runasuser bash "$0" "$@"
  exit
fi

cd ~
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.309.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.309.0.tar.gz
./config.sh --url $1 --token $2 --labels $3 --unattended
./run.sh install
./run.sh start
