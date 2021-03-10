pragma solidity >=0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "../MerkleDistributor.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function doClaim (MerkleDistributor distributor, uint index, uint amount, bytes32[] calldata merkleProof) external {
        distributor.claim(index, address(this), amount, merkleProof);
    }
}

contract MerkleDistributorSmallTreeTest is DSTest {
    Hevm hevm;

    DSToken prot;
    MerkleDistributor distributor;
    bytes32 merkleRoot;
    bytes32[] proofs;

    User alice;
    User bob;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        alice = new User(); // 0xe58d97b6622134c0436d60daee7fbb8b965d9713, 100 tokens
        bob = new User();   // 0xdb356e865aaafa1e37764121ea9e801af13eeb83, 101 tokens

        emit log_named_address("alice", address(alice));
        emit log_named_address("bob", address(bob));

        //{"merkleRoot":"0x9dbe40ce515d4b56a84de2c4ef60ac81f3e91b290ad57cdc8f4d280add66e46d","tokenTotal":"0xc9","claims":{
        // "0xDB356e865AAaFa1e37764121EA9e801Af13eEb83":{"index":0,"amount":"0x65","proof":["0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9"]},
        // "0xE58d97b6622134C0436d60daeE7FBB8b965D9713":{"index":1,"amount":"0x64","proof":["0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d"]}}}

        merkleRoot = bytes32(0x9dbe40ce515d4b56a84de2c4ef60ac81f3e91b290ad57cdc8f4d280add66e46d);

        prot = new DSToken("PROT", "PROT");
        distributor = new MerkleDistributor(address(prot), merkleRoot);
        prot.mint(address(distributor), 201);

        delete proofs;
    }

    // --- Tests ---
    function test_correct_setup() public {
        assertEq(distributor.token(), address(prot));
        assertEq(distributor.merkleRoot(), merkleRoot);
    }

    function test_claim() public {
        // bob
        proofs.push(bytes32(0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9));
        distributor.claim(0, address(bob), 101, proofs);
        assertEq(prot.balanceOf(address(bob)), 101);
        assertTrue(distributor.isClaimed(0));

        // alice
        proofs[0] = bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d);
        alice.doClaim(distributor, 1, 100, proofs);
        assertEq(prot.balanceOf(address(alice)), 100);
        assertTrue(distributor.isClaimed(1));
    }

    function testFail_claim_twice() public {
        proofs.push(bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d));
        alice.doClaim(distributor, 1, 100, proofs);

        proofs[0] = bytes32(0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9);
        bob.doClaim(distributor, 0, 101, proofs);

        proofs[0] = bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d);
        alice.doClaim(distributor, 1, 100, proofs);
    }

    function testFail_claim_twice2() public {
        proofs.push(bytes32(0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9));
        bob.doClaim(distributor, 0, 101, proofs);

        proofs[0] = bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d);
        alice.doClaim(distributor, 1, 100, proofs);

        proofs[0] = bytes32(0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9);
        bob.doClaim(distributor, 0, 101, proofs);
    }

    function testFail_claim_more() public {
        proofs.push(bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d));
        alice.doClaim(distributor, 1, 101, proofs);
    }

    function testFail_claim_invalid_proof() public {
        proofs.push(bytes32(0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9));
        alice.doClaim(distributor, 1, 100, proofs);
    }

    function testFail_claim_invalid_index() public {
        proofs.push(bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d));
        alice.doClaim(distributor, 1, 100, proofs);
        alice.doClaim(distributor, 0, 100, proofs);
    }

    function testFail_claim_no_token_balance() public {
        proofs.push(bytes32(0xbcaa01503c05685fb1814ac19c20b7bad0a071937b473cc8b4978b857cbfe17d));
        distributor = new MerkleDistributor(address(prot), merkleRoot);
        alice.doClaim(distributor, 1, 100, proofs);
    }

    function testFail_claim_invalid_address() public {
        proofs.push(bytes32(0x1b924cc31c7756cab5ec30b0a57920f9364a527298f388f1bd3182258bf417e9));
        distributor.claim(0, address(alice), 101, proofs);
    }
}

contract MerkleDistributorLargeTreeTest is DSTest {
    Hevm hevm;

    DSToken prot;
    MerkleDistributor distributor;
    bytes32 merkleRoot;
    struct UserData {
        address   user;
        uint      index;
        uint      amount;
        bytes32[] proofs;
    }
    UserData[] users;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        setupUsers();

        merkleRoot = bytes32(0x65b315f4565a40f738cbaaef7dbab4ddefa14620407507d0f2d5cdbd1d8063f6);

        prot = new DSToken("PROT", "PROT");
        distributor = new MerkleDistributor(address(prot), merkleRoot);
        prot.mint(address(distributor), 0x1356);
    }

    function setupUsers() internal {
        // we're using a 99 user tree, below are 8 randomly picked accounts
        // "merkleRoot": "0x65b315f4565a40f738cbaaef7dbab4ddefa14620407507d0f2d5cdbd1d8063f6",
        // "tokenTotal": "0x1356",
        bytes32[] memory proofs = new bytes32[](7);
        proofs[0] = bytes32(0xbde5559f111de5a943ba63074a73444fe4fd7fc9e90fd8af5b1fb5ffd530cf1a);
        proofs[1] = bytes32(0x864a8a8cddd6b0b9903886143b299f090c26ec255201683a560356c47c069f6e);
        proofs[2] = bytes32(0x0995ace724d4822f31aa713b51cacb1db0b584d38baca016aa8013e43c022d1a);
        proofs[3] = bytes32(0xc735b663f8ff0299c2ffa4a11cdce0089dd87a7f18385f26bf81c1e5378165ac);
        proofs[4] = bytes32(0xf87abb4f3f7ee3a71b3030d272d41b0a2e091886debe5ac993f25ed5062a0263);
        proofs[5] = bytes32(0x8179399e0d53673ae8fb6bd81fc538ebb472c9e683173e26cd489cd6c53cb84c);
        proofs[6] = bytes32(0xfdc832bf88b1b4d2327f89edcab7968db8804bfd819a40de7d9015178424b0b7);
        users.push(UserData(0xfA4563612C9De62302364ee8042635e44c8327fF, 98, 0x43, proofs));

        proofs = new bytes32[](7);
        proofs[0] = bytes32(0x98344523f671f29ba77b1198a454c484854bad2e41484b01c881f3733b437e6e);
        proofs[1] = bytes32(0xab7ace346e1b9c6b00c9a503a8bc154032e379c165849757dedcb94299fc806d);
        proofs[2] = bytes32(0xe69b809db0cae478dd0f23c298cb5f42d9745c3d6e2aa91a8a418749e4884007);
        proofs[3] = bytes32(0x3ca14f37b7aed9d02acc71593bcdce65fb708d972301330f34755b1e379fe887);
        proofs[4] = bytes32(0x2c590d853eb730cb7a52242ec00c7f609bf257003cb56b32bcb3aa68754bb20c);
        proofs[5] = bytes32(0x8179399e0d53673ae8fb6bd81fc538ebb472c9e683173e26cd489cd6c53cb84c);
        proofs[6] = bytes32(0xfdc832bf88b1b4d2327f89edcab7968db8804bfd819a40de7d9015178424b0b7);
        users.push(UserData(0xde03a8041B40FF95F7F6b6ca0d1Da80fbBD07925, 91, 0x14, proofs));

        proofs = new bytes32[](3);
        proofs[0] = bytes32(0x6f5d6b7e31ad5da9dc21fa845d60cd8b5c3dad27dcf97bd21d639c5cf84bb106);
        proofs[1] = bytes32(0xa552e265f5d7a3d39fd1f79500b02f10bb5f385bb8f5327db06b209918e9bb41);
        proofs[2] = bytes32(0xfdc832bf88b1b4d2327f89edcab7968db8804bfd819a40de7d9015178424b0b7);
        users.push(UserData(0xB9CcDD7Bedb7157798e10Ff06C7F10e0F37C6BdD, 63, 0x02, proofs));

        proofs = new bytes32[](7);
        proofs[0] = bytes32(0x1419d8cdecc66122fdd450e7322c82dbd1a183b4abad7ed01637042fcbbb1231);
        proofs[1] = bytes32(0x79be08e672b91905bbbfa785ba28cf962112aae1bc30911e74e1af3939e7501f);
        proofs[2] = bytes32(0x0a9ae0952dd27639b419a19a4915049dab8d969025dd2b5dd3d41d189ab741b6);
        proofs[3] = bytes32(0xff2cdff30a8b335d489ac2b79ae2807547ab391cd83f208efe09383cd43c6a1b);
        proofs[4] = bytes32(0x37a9403fe61c38ad4a12b00106d091994901f4a6365af9584ff4b2710acb4961);
        proofs[5] = bytes32(0x023527b3cb4eb23b75f8554373ef468c6cc5a446a5bbf5b26133d684a82dc8ee);
        proofs[6] = bytes32(0xa8390642d0b4fcbcfd25bd2787f9e498ce1f24c3d630f57a1560354a5b4dd06e);
        users.push(UserData(0x012ed55a0876Ea9e58277197DC14CbA47571CE28, 0, 0x55, proofs));

        proofs = new bytes32[](4);
        proofs[0] = bytes32(0xeebde9b280704b351bb6517e6019dc48011d17eed56d9c04488094fe8f6bd5f2);
        proofs[1] = bytes32(0xfd713e18861887608ae9879534adacb3eabc6e7c4c28e398af3b57137349463c);
        proofs[2] = bytes32(0xa552e265f5d7a3d39fd1f79500b02f10bb5f385bb8f5327db06b209918e9bb41);
        proofs[3] = bytes32(0xfdc832bf88b1b4d2327f89edcab7968db8804bfd819a40de7d9015178424b0b7);
        users.push(UserData(0x01dC7F8C928CeA27D8fF928363111c291bEB20b1, 1, 0x58, proofs));

        proofs = new bytes32[](7);
        proofs[0] = bytes32(0xb9382cb9537f8dbbd4268aef9ed9d8b7e63e6cae7cef3526796708b060dd7c87);
        proofs[1] = bytes32(0x8f27e07095dbe81e4385f5330e9213d36fc213d6cda5f5480119c084e471473d);
        proofs[2] = bytes32(0xe4e1b3c0bfdb26fc8b15e9d435895f0ef76d89f9380e8fb82a6a6cc8fc10f439);
        proofs[3] = bytes32(0xc735b663f8ff0299c2ffa4a11cdce0089dd87a7f18385f26bf81c1e5378165ac);
        proofs[4] = bytes32(0xf87abb4f3f7ee3a71b3030d272d41b0a2e091886debe5ac993f25ed5062a0263);
        proofs[5] = bytes32(0x8179399e0d53673ae8fb6bd81fc538ebb472c9e683173e26cd489cd6c53cb84c);
        proofs[6] = bytes32(0xfdc832bf88b1b4d2327f89edcab7968db8804bfd819a40de7d9015178424b0b7);
        users.push(UserData(0x1fCBa490902B2BD44ba98359C7075e2C8a2b9F15, 10, 0x2d, proofs));

        proofs = new bytes32[](7);
        proofs[0] = bytes32(0xa4f5309796dc99dceed3bf8e72c0bfa27efd8f520f87696ee290698836e44e23);
        proofs[1] = bytes32(0x70dbc08b6e0a3d2b29eccda232fb468f7b11cd6a2cb00cdb81e2af12d4195a99);
        proofs[2] = bytes32(0x0f91a9a4a8c093ca281806f52c252a754f5a46362abe5be60fd925261be11765);
        proofs[3] = bytes32(0x9289b0738b4385bb4a21ec0348eed9eb276a0089126928510984d211bdd2326a);
        proofs[4] = bytes32(0x2c590d853eb730cb7a52242ec00c7f609bf257003cb56b32bcb3aa68754bb20c);
        proofs[5] = bytes32(0x8179399e0d53673ae8fb6bd81fc538ebb472c9e683173e26cd489cd6c53cb84c);
        proofs[6] = bytes32(0xfdc832bf88b1b4d2327f89edcab7968db8804bfd819a40de7d9015178424b0b7);
        users.push(UserData(0x5A553d59435Df0688fd5dEa1aa66C7430541ffB3, 28, 0x63, proofs));

        proofs = new bytes32[](7);
        proofs[0] = bytes32(0x0a0177f7752de1127d9c349677f58cd25b59355a27b29cd3e77fd49f6bc30d9a);
        proofs[1] = bytes32(0xf4b6ad879c695dbdb0376fca8b9548cc4718bd08e0e657732b3b9df595a71dba);
        proofs[2] = bytes32(0xc37bf5b48fd7a4640107ef123ae21c5af58e79266cf65e41bbbed0480c3d2c08);
        proofs[3] = bytes32(0xedc664bfdaba16701ff14c0fbd5c2cd9e349f6d9051f837b6848d361c7c0b59c);
        proofs[4] = bytes32(0x37a9403fe61c38ad4a12b00106d091994901f4a6365af9584ff4b2710acb4961);
        proofs[5] = bytes32(0x023527b3cb4eb23b75f8554373ef468c6cc5a446a5bbf5b26133d684a82dc8ee);
        proofs[6] = bytes32(0xa8390642d0b4fcbcfd25bd2787f9e498ce1f24c3d630f57a1560354a5b4dd06e);
        users.push(UserData(0xc0B7C64d370A9ffcFb9ef675809126c5cAfA9619, 84, 0x18, proofs));
    }

    // --- Tests ---
    function test_correct_setup() public {
        assertEq(distributor.token(), address(prot));
        assertEq(distributor.merkleRoot(), merkleRoot);
    }

    function test_claim(uint user1seed, uint user2seed) public {
        UserData storage user1 = users[user1seed % users.length];
        distributor.claim(user1.index, user1.user, user1.amount,user1.proofs);
        assertEq(prot.balanceOf(user1.user), user1.amount);
        assertTrue(distributor.isClaimed(user1.index));

        UserData storage user2 = users[user2seed % users.length];
        if (user1.index != user2.index) {
            distributor.claim(user2.index, user2.user, user2.amount, user2.proofs);
            assertEq(prot.balanceOf(user2.user), user2.amount);
            assertTrue(distributor.isClaimed(user2.index));
        }
    }

    function testFail_claim_twice(uint userSeed) public {
        UserData storage user = users[0];
        // claiming all
        for (uint i = 0; i < users.length; i++) {
            user = users[i];
            distributor.claim(user.index, user.user, user.amount, user.proofs);
        }
        // random user claims twice
        user = users[userSeed % users.length];
        distributor.claim(user.index, user.user, user.amount, user.proofs);
    }

    function testFail_claim_more(uint userSeed, uint amountOffset) public {
        if (amountOffset == 0) amountOffset++;
        UserData storage user = users[userSeed % users.length];
        distributor.claim(user.index, user.user, user.amount + amountOffset, user.proofs);
    }

    function testFail_claim_invalid_proof(uint userSeed, uint proofChangeSeed, bytes32 wrongProof) public {
        UserData storage user = users[userSeed % users.length];
        user.proofs[proofChangeSeed % user.proofs.length] = wrongProof;
        distributor.claim(user.index, user.user, user.amount, user.proofs);
    }

    function testFail_claim_invalid_index(uint userSeed, uint amountOffset) public {
        UserData storage user = users[userSeed % users.length];
        if (amountOffset == 0) amountOffset++;
        distributor.claim(user.index + amountOffset, user.user, user.amount, user.proofs);
    }

    function testFail_claim_invalid_address(uint userSeed, address wrongAddress) public {
        UserData storage user = users[userSeed % users.length];
        distributor.claim(user.index, wrongAddress, user.amount, user.proofs);
    }
}
