import { EventLog, Log } from "ethers";
import { ethers } from "hardhat";

import * as fs from "fs";
import * as path from "path";

async function main() {
  const abi = [
    "event VaultWhitelistedStatusUpdated(address indexed receiver, bool indexed isWhitelisted, string metadata)",
  ];

  const contract = await ethers.getContractAt(
    abi,
    "0xdf960E8F3F19C481dDE769edEDD439ea1a63426a"
  );

  // paginate
  const currentBlock = await ethers.provider.getBlockNumber();

  const events: (EventLog | Log)[] = [];

  let blockNumber = 8000; // start at block 8000

  while (blockNumber < currentBlock) {
    const promises = [];
    for (let i = 0; i < 5; i++) {
      promises.push(
        contract.queryFilter(
          "VaultWhitelistedStatusUpdated",
          blockNumber,
          blockNumber + 10000
        )
      );
      blockNumber += 10000;
    }

    console.log("processing block:", blockNumber);

    const _events = await Promise.all(promises);

    events.push(..._events.flat(1));
  }

  const vaults = events
    .filter((event: any) => {
      // filter for events that has isWhitelisted==true
      return event.args[1];
    })
    .map((event: any) => {
      // map to the bera vault address
      return event.args[0];
    });

  const jsonString = JSON.stringify({ vaults });

  const filePath = path.join(__dirname, `../output/whitelistedBeraVaults.json`);
  await fs.promises.writeFile(filePath, jsonString, { flag: "w+" });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
