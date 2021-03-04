pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./MerkleDistributor.sol";

contract MerkleDistributorTest is DSTest {
    MerkleDistributor distributor;

    function setUp() public {
        distributor = new MerkleDistributor();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
