pragma solidity 0.6.7;

import "./MerkleDistributor.sol";

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

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DeployDistributor(uint256 id, address distributor);

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
    function deployDistributor(bytes32 merkleRoot) external isAuthorized {
        nonce = addition(nonce, 1);
        address newDistributor = address(new MerkleDistributor(distributedToken, merkleRoot));
        distributors[nonce]    = newDistributor;
        emit DeployDistributor(nonce, newDistributor);
    }
}
