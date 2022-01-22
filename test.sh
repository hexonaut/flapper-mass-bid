#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  forge test --rpc-url="$ETH_RPC_URL" --optimize
else
  forge test --rpc-url="$ETH_RPC_URL" --optimize --match "$1" -vvvv
fi
