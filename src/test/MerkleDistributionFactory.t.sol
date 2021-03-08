pragma solidity >=0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "../MerkleDistributorFactory.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function doDeployDistributor (MerkleDistributorFactory factory, bytes32 merkleRoot) external {
        factory.deployDistributor(merkleRoot);
    }
}

contract MerkleDistributorFactoryTest is DSTest {
    Hevm hevm;

    DSToken prot;
    MerkleDistributorFactory factory;

    User alice;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        alice = new User();
        prot = new DSToken("PROT", "PROT");

        factory = new MerkleDistributorFactory(address(prot));
    }

    // --- Tests ---
    function test_correct_setup() public {
        assertEq(factory.authorizedAccounts(address(this)), uint(1));
        assertEq(factory.nonce(), 0);
        assertEq(factory.distributedToken(), address(prot));
    }

    function test_deploy_distributor_fuzz(bytes32[8] memory merkleRoot) public {
        for (uint i = 0; i < merkleRoot.length; i++) {
            factory.deployDistributor(merkleRoot[0]);

            assertEq(factory.authorizedAccounts(address(this)), uint(1));
            assertEq(factory.nonce(), i + 1);
            assertEq(factory.distributedToken(), address(prot));

            assertEq(MerkleDistributor(factory.distributors(i + 1)).token(), address(prot));
            assertEq(MerkleDistributor(factory.distributors(i + 1)).merkleRoot(), merkleRoot[0]);
        }
    }

    function testFail_deploy_unauthorized(bytes32 merkleRoot) public {
        alice.doDeployDistributor(factory, merkleRoot);
    }
}