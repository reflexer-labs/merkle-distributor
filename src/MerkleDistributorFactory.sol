pragma solidity 0.6.7;

import "./MerkleDistributor.sol";

import "./openzeppelin/IERC20.sol";

contract MerkleDistributorFactory {
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

    // --- Variables ---
    // Number of distributors created
    uint256 public nonce;
    // The token that's being distributed by every merkle distributor
    address public distributedToken;
    // Mapping of ID => distributor address
    mapping(uint256 => address) public distributors;
    // Tokens left to distribute to every distributor
    mapping(uint256 => uint256) public tokensToDistribute;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DeployDistributor(uint256 id, address distributor, uint256 tokenAmount);
    event SendTokensToDistributor(uint256 id);

    constructor(address distributedToken_) public {
        require(distributedToken_ != address(0), "MerkleDistributorFactory/null-distributed-token");

        authorizedAccounts[msg.sender] = 1;
        distributedToken               = distributedToken_;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MerkleDistributorFactory/add-uint-uint-overflow");
    }

    // --- Core Logic ---
    /*
    * @notice Deploy a new merkle distributor
    * @param merkleRoot The merkle root used in the distributor
    */
    function deployDistributor(bytes32 merkleRoot, uint256 tokenAmount) external isAuthorized {
        require(tokenAmount > 0, "MerkleDistributorFactory/null-token-amount");
        nonce                     = addition(nonce, 1);
        address newDistributor    = address(new MerkleDistributor(distributedToken, merkleRoot));
        distributors[nonce]       = newDistributor;
        tokensToDistribute[nonce] = tokenAmount;
        emit DeployDistributor(nonce, newDistributor, tokenAmount);
    }
    /*
    * @notice Send tokens to a distributor
    * @param nonce The nonce/id of the distributor to send tokens to
    */
    function sendTokensToDistributor(uint256 nonce) external isAuthorized {
        require(tokensToDistribute[nonce] > 0, "MerkleDistributorFactory/nothing-to-send");
        uint256 tokensToSend = tokensToDistribute[nonce];
        tokensToDistribute[nonce] = 0;
        IERC20(distributedToken).transfer(distributors[nonce], tokensToSend);
        emit SendTokensToDistributor(nonce);
    }
    /*
    * @notice Sent distributedToken tokens out of this contract and to a custom destination
    * @param dst The address that will receive tokens
    * @param tokenAmount The token amount to send
    */
    function getBackTokens(address dst, uint256 tokenAmount) external isAuthorized {
        require(dst != address(0), "MerkleDistributorFactory/null-dst");
        IERC20(distributedToken).transfer(dst, tokenAmount);
    }
}
