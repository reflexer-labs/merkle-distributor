pragma solidity >=0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "../MerkleDistributorFactory.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function doDeployDistributor(MerkleDistributorFactory factory, bytes32 merkleRoot, uint256 tokenAmount) external {
        factory.deployDistributor(merkleRoot, tokenAmount);
    }
    function doSendTokensToDistributor(MerkleDistributorFactory factory, uint256 id) external {
        factory.sendTokensToDistributor(id);
    }
    function doGetBackTokens(MerkleDistributorFactory factory, address dst, uint256 tokenAmount) external {
        factory.getBackTokens(dst, tokenAmount);
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

    function test_send_tokens_to_distributor() public {
        prot.mint(address(factory), 5E18);
        factory.deployDistributor(keccak256(abi.encode("seed")), 5E18);
        factory.sendTokensToDistributor(1);

        assertEq(prot.balanceOf(address(factory)), 0);
        assertEq(prot.balanceOf(factory.distributors(1)), 5E18);
    }

    function testFail_send_tokens_to_same_distributor_twice() public {
        prot.mint(address(factory), 10E18);
        factory.deployDistributor(keccak256(abi.encode("seed")), 5E18);
        factory.sendTokensToDistributor(1);
        factory.sendTokensToDistributor(1);
    }

    function testFail_send_tokens_to_distributor_by_unauthed() public {
        prot.mint(address(factory), 10E18);
        factory.deployDistributor(keccak256(abi.encode("seed")), 5E18);
        alice.doSendTokensToDistributor(factory, 1);
    }

    function test_get_back_tokens() public {
        prot.mint(address(factory), 10E18);
        factory.getBackTokens(address(0x1), 5E18);

        assertEq(prot.balanceOf(address(factory)), 5E18);
        assertEq(prot.balanceOf(address(0x1)), 5E18);

        factory.getBackTokens(address(0x1), 5E18);

        assertEq(prot.balanceOf(address(factory)), 0);
        assertEq(prot.balanceOf(address(0x1)), 10E18);
    }

    function testFail_get_back_tokens_by_unauthed() public {
        prot.mint(address(factory), 10E18);
        alice.doGetBackTokens(factory, address(0x1), 5E18);
    }

    function testFail_get_back_tokens_send_to_addr_zero() public {
        prot.mint(address(factory), 10E18);
        factory.getBackTokens(address(0), 5E18);
    }

    function test_deploy_distributor_fuzz(bytes32[8] memory merkleRoot) public {
        for (uint i = 0; i < merkleRoot.length; i++) {
            factory.deployDistributor(merkleRoot[0], i * 1E18);

            assertEq(factory.authorizedAccounts(address(this)), uint(1));
            assertEq(factory.nonce(), i + 1);
            assertEq(factory.distributedToken(), address(prot));
            assertEq(factory.tokensToDistribute(i + 1), i * 1E18);

            assertEq(MerkleDistributor(factory.distributors(i + 1)).token(), address(prot));
            assertEq(MerkleDistributor(factory.distributors(i + 1)).merkleRoot(), merkleRoot[0]);
        }
    }

    function testFail_deploy_unauthorized(bytes32 merkleRoot) public {
        alice.doDeployDistributor(factory, merkleRoot, 1E18);
    }
}
