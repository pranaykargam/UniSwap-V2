// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @title UniswapV2ERC20
/// @notice LP token for Uniswap V2 pairs. ERC-20 with EIP-2612 permit.
/// @dev This is the base contract that UniswapV2Pair inherits from.


contract UniswapV2ERC20 {

      // -- Type declarations (none here) --

         // -- State variables (group similarly) --
    string public constant name = "Uniswap V2";
    string public constant symbol = "UNI-V2";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    // EIP-2612 (permit) related state
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

        // nonce: Prevents signature replay attacks; each permit signature can only be used once 
    mapping(address => uint256) public nonces;

        // -- Events --

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }
}

