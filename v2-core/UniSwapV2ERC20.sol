// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @title UniswapV2ERC20
/// @notice LP token for Uniswap V2 pairs. ERC-20 with EIP-2612 permit.
/// @dev This is the base contract that UniswapV2Pair inherits from.


// implements the ERC20 token standard for Uniswap V2 liquidity pool tokens (also called LP tokens or pair tokens).
// It tracks ownership of liquidity pool shares. When liquidity providers add funds to a pool, they receive these ERC20 tokens representing their share of the pool.
// It manages permit functionality (gasless approvals via signed messages) using EIP-2612
// ERC-20 = "Ethereum Request for Comments 20" 

contract UniSwapV2ERC20 {


         //  State variables (group similarly) 
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

// ## immutable + constructor
// 	Factory/WETH set once at deploy, stored in bytecode (not storage), can never change
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

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            allowance[from][msg.sender] = currentAllowance - value;
        }
        _transfer(from, to, value);
        return true;
    }


    // ecrecover(digest, v, r, s) is a Solidity built-in function that recovers the signer's Ethereum address from a digital signature.
    // Parameters:
      // digest — the hash of the message/data that was signed
      // v — recovery identifier (27 or 28, tells which public key to recover)
      // r — first part of the ECDSA signature (32 bytes)
      // s — second part of the ECDSA signature (32 bytes)
      // Returns: The address of the private key holder who signed the message.


    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01", // -- EIP-712 header (2 bytes)
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UniswapV2: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}



