import { BigNumber, utils } from "ethers";
import BalanceTree from "./balance-tree";

const { isAddress, getAddress } = utils;

export interface MerkleDistributorInfo {
  merkleRoot: string;
  tokenTotal: string;
  description: string;
  recipients: {
    [account: string]: {
      index: number;
      amount: string;
      proof: string[];
    };
  };
}

type OldFormat = { [account: string]: string };
type NewFormat = { address: string; earnings: string };

export function parseBalanceMap(
  balances: OldFormat,
  description: string
): MerkleDistributorInfo {
  // if balances are in an old format, process them
  const balancesInNewFormat: NewFormat[] = Object.keys(balances).map(
    (account): NewFormat => ({
      address: account,
      earnings: balances[account],
    })
  );
  const dataByAddress = balancesInNewFormat.reduce<{
    [address: string]: {
      amount: BigNumber;
      flags?: { [flag: string]: boolean };
    };
  }>((memo, { address: account, earnings }) => {
    if (!isAddress(account)) {
      throw new Error(`Found invalid address: ${account}`);
    }
    const parsed = getAddress(account);
    if (memo[parsed]) throw new Error(`Duplicate address: ${parsed}`);
    const parsedNum = BigNumber.from(earnings);
    if (parsedNum.lte(0))
      throw new Error(`Invalid amount for account: ${account}`);

    memo[parsed] = { amount: parsedNum };
    return memo;
  }, {});

  const sortedAddresses = Object.keys(dataByAddress).sort();

  // construct a tree
  const tree = new BalanceTree(
    sortedAddresses.map((address) => ({
      account: address,
      amount: dataByAddress[address].amount,
    }))
  );

  // generate merkle paths
  const recipients = sortedAddresses.reduce<{
    [address: string]: {
      amount: string;
      index: number;
      proof: string[];
    };
  }>((memo, address, index) => {
    const { amount } = dataByAddress[address];
    memo[address] = {
      index,
      amount: amount.toHexString(),
      proof: tree.getProof(index, address, amount),
    };
    return memo;
  }, {});

  const tokenTotal: BigNumber = sortedAddresses.reduce<BigNumber>(
    (memo, key) => memo.add(dataByAddress[key].amount),
    BigNumber.from(0)
  );

  return {
    merkleRoot: tree.getHexRoot(),
    tokenTotal: tokenTotal.toHexString(),
    description,
    recipients,
  };
}
