// SPDX-License-Identifier: UNLICENSED
// Forked from: https://github.com/Uniswap/merkle-distributor

pragma solidity 0.6.7;

import "./openzeppelin/IERC20.sol";
import "./openzeppelin/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "MerkleDistributorFactory/account-not-authorized");
        _;
    }
    /*
    * @notify Checks whether an address can send tokens out of this contract
    */
    modifier canSendTokens {
        require(
          either(authorizedAccounts[msg.sender] == 1, both(owner == msg.sender, now >= addition(deploymentTime, timelapseUntilWithdrawWindow))),
          "MerkleDistributorFactory/cannot-send-tokens"
        );
        _;
    }

    // The token being distributed
    address public immutable override token;
    // The owner of this contract
    address public immutable override owner;
    // The merkle root of all addresses that get a distribution
    bytes32 public immutable override merkleRoot;
    // Timestamp when this contract was deployed
    uint256 public immutable override deploymentTime;

    // This is a packed array of booleans
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        authorizedAccounts[msg.sender] = 1;
        owner                          = msg.sender;
        token                          = token_;
        merkleRoot                     = merkleRoot_;
        deploymentTime                 = now;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MerkleDistributorFactory/add-uint-uint-overflow");
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Send tokens to an authorized address
    * @param dst The address to send tokens to
    * @param tokenAmount The amount of tokens to send
    */
    function sendTokens(address dst, uint256 tokenAmount) external override canSendTokens {
        require(dst != address(0), "MerkleDistributorFactory/null-dst");
        IERC20(token).transfer(dst, tokenAmount);
        emit SendTokens(dst, tokenAmount);
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
