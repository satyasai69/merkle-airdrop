// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

/**
 * @title MerkleAirdrop
 * @author me
 * @notice  Airdrop tokens to users who can prove they are in a merkle tree
 */
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MerkleAirdrop__InvaildProof();
    error MerkleAirdrop__AlreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                            STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_markleRoot;
    mapping(address => bool) s_airdropClaimed;

    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 _markleRoot, IERC20 _airdropToken) {
        i_markleRoot = _markleRoot;
        i_airdropToken = _airdropToken;
    }
    /*//////////////////////////////////////////////////////////////
                         PUBLIC & EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    function claim(address _account, uint256 _amount, bytes32[] calldata _markleProof) external {
        if (s_airdropClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        s_airdropClaimed[_account] = true;

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));

        bool check = MerkleProof.verify(_markleProof, i_markleRoot, leaf);

        if (!check) {
            revert MerkleAirdrop__InvaildProof();
        }

        i_airdropToken.safeTransfer(_account, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMarkleRoot() public view returns (bytes32) {
        return i_markleRoot;
    }

    function getAirdropToken() public view returns (IERC20) {
        return i_airdropToken;
    }
}
