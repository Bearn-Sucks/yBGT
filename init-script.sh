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
grep -rl --include \*.sol "openzeppelin\/" ./lib/berachain-contracts/ | xargs sed -i "s/openzeppelin\//openzeppelin-bera\//g"
grep -rl --include \*.sol "\"src\/" ./lib/berachain-contracts/ | xargs sed -i "s/\"src\//\"@berachain\/contracts\//g"
grep -rl --include \*.sol "\"test\/" ./lib/berachain-contracts/ | xargs sed -i "s/\"test\//\"@berachain\/test\//g"
grep -rl --include \*.sol "0.8.26;" ./lib/berachain-contracts/ | xargs sed -i "s/0.8.26;/0.8.27;/g"
echo "finished replacing submodule remappings"
