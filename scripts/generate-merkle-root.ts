import { program } from "commander";
import fs from "fs";
import {
  MerkleDistributorInfo,
  parseBalanceMap,
} from "./lib/parse-balance-map";
import { utils } from "ethers";

program
  .version("0.0.0")
  .requiredOption(
    "-i, --input <path>",
    "input CSV file location in the format 'Address,amount wad'"
  )
  .requiredOption(
    "-n, --network <mainnet|kovan>",
    "Network to publish the distribution"
  )
  .requiredOption(
    "-d, --description <text>",
    "Short description of the distribution"
  );

program.parse(process.argv);

// Convert CSV to JSON
const json: { [address: string]: string } = {};

fs.readFileSync(program.opts().input, "utf8")
  .split("\n")
  .map((x) => {
    const kv = x.split(",");
    if (kv[0] === "" || kv[0].slice(0, 2) !== "0x") return;

    // Convert number to wad
    json[kv[0]] = utils.parseEther(kv[1]).toString();
  });

const newDistribution = parseBalanceMap(json, program.opts().description);

const outPath = `scripts/merkle-paths-output/${program.opts().network}.json`;
const allDistributions: MerkleDistributorInfo[] = JSON.parse(
  fs.readFileSync(outPath, "utf8")
);
allDistributions.push(newDistribution);
fs.writeFileSync(outPath, JSON.stringify(allDistributions, null, 4));
