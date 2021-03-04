// SPDX-License-Identifier: UNLICENSED
// Forked from: https://github.com/Uniswap/merkle-distributor

pragma solidity 0.6.7;

import "./openzeppelin/IERC20.sol";
import "./openzeppelin/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    // The token being distributed
    address public immutable override token;
    // The merkle root of all addresses that get a distribution
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    /*
    * @notice View function returning whether an address has already claimed their tokens
    * @param index The position of the address inside the merkle tree
    */
    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
    /*
    * @notice Mark an address as having claimed their distribution
    * @param index The position of the address inside the merkle tree
    */
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
    /*
    * @notice Claim your distribution
    * @param index The position of the address inside the merkle tree
    * @param account The actual address from the tree
    * @param amount The amount being distributed
    * @param merkleProof The merkle path used to prove that the address is in the tree and can claim amount tokens
    */
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor/drop-already-claimed');

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor/invalid-proof');

        // Mark it claimed and send the token
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor/transfer-failed');

        emit Claimed(index, account, amount);
    }
}
