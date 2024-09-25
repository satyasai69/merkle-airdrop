// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BagelToken} from "src/BagelToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {Deploy} from "script/Deploy.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract MarkleAirdropTest is Test, ZkSyncChainChecker {
    BagelToken bagelToken;
    MerkleAirdrop merkleAirdrop;

    uint256 public constant MINT_AMOUNT = 6 * 25 ether;

    bytes32 public ROOT = 0xd89b9502e5cb180ab85c842f737062c732b95e32b925c4474d0294336ac5d047;

    bytes32 public PROOF_ONE = 0x0c7ef881bb675a5858617babe0eb12b538067e289d35d5b044ee76b79d335191;
    bytes32 public PROOF_TWO = 0x81f0e530b56872b6fc3e10f8873804230663f8407e21cef901b8aeb06a25e5e2;
    bytes32 public PROOF_THREE = 0x4a3460d3b7cb1d8a0ffb1583548a8e98a0594af113553644817db99624bb2e7a;

    bytes32[] public PROOF = [PROOF_ONE, PROOF_TWO, PROOF_THREE];

    uint256 public constant AMOUNT = 25 * 1e18;

    address USER;
    uint256 userPrivateKey;

    address USER2;
    uint256 userPrivateKey2;

    address GASPAYER;

    function setUp() public {
        if (!isZkSyncChain()) {
            Deploy depolyer = new Deploy();

            (bagelToken, merkleAirdrop) = depolyer.run();
        } else {
            bagelToken = new BagelToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, bagelToken);

            bagelToken.mint(address(merkleAirdrop), MINT_AMOUNT);
        }

        (USER, userPrivateKey) = makeAddrAndKey("USER");
        (USER2, userPrivateKey2) = makeAddrAndKey("USER2");
        address GASPAYER = makeAddr("GASPAYER");
    }

    function testUserCanClaim() public {
        uint256 startingBalance = bagelToken.balanceOf(USER);
        bytes32 digest = merkleAirdrop.getMessageHash(USER, AMOUNT);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.prank(GASPAYER);
        merkleAirdrop.claim(address(USER), AMOUNT, PROOF, v, r, s);

        uint256 endingBalance = bagelToken.balanceOf(USER);

        assertEq(AMOUNT, endingBalance - startingBalance);

        console.log("EndingBalance :", endingBalance);
    }

    function testUserNotonList() public {
        uint256 startingBalance = bagelToken.balanceOf(USER2);
        bytes32 digest = merkleAirdrop.getMessageHash(USER2, AMOUNT);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey2, digest);

        vm.prank(GASPAYER);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvaildProof.selector);
        merkleAirdrop.claim(address(USER2), AMOUNT, PROOF, v, r, s);

        uint256 endingBalance = bagelToken.balanceOf(USER2);

        assertEq(startingBalance, endingBalance);

        console.log("EndingBalance :", endingBalance);
    }

    function testIfUserAlreadlyClaimItsRevert() public {
        uint256 startingBalance = bagelToken.balanceOf(USER);
        bytes32 digest = merkleAirdrop.getMessageHash(USER, AMOUNT);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.startPrank(GASPAYER);
        merkleAirdrop.claim(address(USER), AMOUNT, PROOF, v, r, s);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        merkleAirdrop.claim(address(USER), AMOUNT, PROOF, v, r, s);

        vm.stopPrank();
        uint256 endingBalance = bagelToken.balanceOf(USER);
        assertEq(AMOUNT, endingBalance - startingBalance);

        console.log("EndingBalance :", endingBalance);
    }
}
