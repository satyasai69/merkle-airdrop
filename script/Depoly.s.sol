// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BagelToken} from "src/BagelToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

contract Depoly is Script {
    BagelToken bagelToken;
    MerkleAirdrop merkleAirdrop;

    uint256 public constant MINT_AMOUNT = 6 * 25 ether;

    bytes32 public ROOT = 0xd89b9502e5cb180ab85c842f737062c732b95e32b925c4474d0294336ac5d047;

    function run() public returns (BagelToken, MerkleAirdrop) {
        vm.startBroadcast();
        bagelToken = new BagelToken();
        merkleAirdrop = new MerkleAirdrop(ROOT, bagelToken);

        bagelToken.mint(address(merkleAirdrop), MINT_AMOUNT);

        vm.stopBroadcast();

        return (bagelToken, merkleAirdrop);
    }
}
