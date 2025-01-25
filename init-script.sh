#!/bin/sh

forge install

cd "lib/berachain-contracts"
npm install
cd ../..

# Replaces mentions of @openzepplin with submodule specific names
# This is needed because forge can't resolve these dependencies properly
# https://github.com/foundry-rs/foundry/issues/5447
# https://github.com/foundry-rs/foundry/pull/5532
# ^the fix wasn't working and the PR was reverted

echo "replacing submodule remappings..."
find "./lib/berachain-contracts" -type f -name '*.sol' -exec \
	sed -i "s/openzeppelin\//openzeppelin-bera\//g" {} +
find "./lib/yearn-tokenized-strategy-periphery" -type f -name '*.sol' -exec \
	sed -i "s/openzeppelin\//openzeppelin-yearn\//g" {} +
echo "finished replacing submodule remappings"
