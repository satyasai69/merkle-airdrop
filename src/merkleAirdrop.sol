// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

/**
 * @title MerkleAirdrop
 * @author me
 * @notice  Airdrop tokens to users who can prove they are in a merkle tree
 */
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MerkleAirdrop__InvaildProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                            STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AidropClaim {
        address account;
        uint256 amount;
    }

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_markleRoot;
    mapping(address => bool) s_airdropClaimed;

    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 _markleRoot, IERC20 _airdropToken) EIP712("MerkleAirdrop", "1") {
        i_markleRoot = _markleRoot;
        i_airdropToken = _airdropToken;
    }
    /*//////////////////////////////////////////////////////////////
                         PUBLIC & EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    function claim(address _account, uint256 _amount, bytes32[] calldata _markleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_airdropClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(_account, getMessage(_account, _amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
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

    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AidropClaim({account: account, amount: amount}))));
    }

    function getMarkleRoot() public view returns (bytes32) {
        return i_markleRoot;
    }

    function getAirdropToken() public view returns (IERC20) {
        return i_airdropToken;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
