// SPDX-License-Identifier: UNLICENSED
// Forked from: https://github.com/Uniswap/merkle-distributor

pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root
abstract contract IMerkleDistributor {
    // Returns the address of the token distributed by this contract
    function token() virtual external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim
    function merkleRoot() virtual external view returns (bytes32);
    // Returns true if the index has been marked claimed
    function isClaimed(uint256 index) virtual external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) virtual external;

    // This event is triggered whenever a call to #claim succeeds
    event Claimed(uint256 index, address account, uint256 amount);
}
