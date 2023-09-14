#!/bin/sh

if [ "`whoami`" != "runasuser" ]; then
  useradd -m runasuser
  cp "$0" /home/runasuser/
  chown runasuser:runasuser /home/runasuser/script.sh
  chmod 750 /home/runasuser/script.sh
  sudo -u runasuser sh "/home/runasuser/script.sh" "$@"
  exit
fi

cd ~
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.309.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.309.0.tar.gz
./config.sh --url $1 --token $2 --labels $3 --unattended
./run.sh install
./run.sh start
