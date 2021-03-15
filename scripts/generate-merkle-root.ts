import { program } from "commander";
import fs from "fs";
import { parseBalanceMap } from "./lib/parse-balance-map";
import { utils } from "ethers";

program
  .version("0.0.0")
  .requiredOption(
    "-i, --input <path>",
    "input CSV file location in the format 'Address,amount wad'"
  )
  .requiredOption(
    "-o, --output <path>",
    "Output JSON file with all merkle paths"
  )
  .requiredOption(
    "-d, --description <text>",
    "Short description of the distribution"
  );


program.parse(process.argv);

// Convert CSV to JSON
const json: {[address: string]: string} = {}

fs.readFileSync(program.opts().input, "utf8" ).split("\n").map(x => {
    const kv = x.split(',')
    if(kv[0] === '' || kv[0].slice(0,2) !== "0x") return;
    // Convert number to wad
    json[kv[0]] = utils.parseEther((Number(kv[1]).toFixed(18))).toString()
})

const out = parseBalanceMap(json, program.opts().description)
fs.writeFileSync(program.opts().output, JSON.stringify(out));
