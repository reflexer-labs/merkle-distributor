// SPDX-License-Identifier: UNLICENSED
// Forked from: https://github.com/Uniswap/merkle-distributor

pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root
abstract contract IMerkleDistributor {
    // Time from the moment this contract is deployed and until the owner can withdraw leftover tokens
    uint256 public constant timelapseUntilWithdrawWindow = 90 days;

    // Returns the address of the token distributed by this contract
    function token() virtual external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim
    function merkleRoot() virtual external view returns (bytes32);
    // Returns the timestamp when this contract was deployed
    function deploymentTime() virtual external view returns (uint256);
    // Returns the address for the owner of this contract
    function owner() virtual external view returns (address);
    // Returns true if the index has been marked claimed
    function isClaimed(uint256 index) virtual external view returns (bool);
    // Send tokens to an address without that address claiming them
    function sendTokens(address dst, uint256 tokenAmount) virtual external;
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) virtual external;

    // This event is triggered whenever an address is added to the set of authed addresses
    event AddAuthorization(address account);
    // This event is triggered whenever an address is removed from the set of authed addresses
    event RemoveAuthorization(address account);
    // This event is triggered whenever a call to #claim succeeds
    event Claimed(uint256 index, address account, uint256 amount);
    // This event is triggered whenever some tokens are sent to an address without that address claiming them
    event SendTokens(address dst, uint256 tokenAmount);
}
