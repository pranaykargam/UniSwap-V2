// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UniswapV2ERC20} from "../src/UniSwapV2ERC20.sol";

contract UniswapV2ERC20TestHarness is UniswapV2ERC20 {
    function mint(address to, uint256 value) external {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        _burn(from, value);
    }
}

contract UniswapV2ERC20Test is Test {
    UniswapV2ERC20TestHarness private token;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private carol = makeAddr("carol");

    uint256 private aliceKey = 0xA11CE;
    uint256 private constant INITIAL_SUPPLY = 1_000 ether;

    function setUp() public {
        token = new UniswapV2ERC20TestHarness();
        token.mint(alice, INITIAL_SUPPLY);
    }

    // 1. Metadata
    function testMetadata() public view {
        assertEq(token.name(), "Uniswap V2");
        assertEq(token.symbol(), "UNI-V2");
        assertEq(token.decimals(), 18);
    }

    // 2. DOMAIN_SEPARATOR is set in constructor
    function testDomainSeparator() public view {
        bytes32 expected = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(token.name())),
                keccak256(bytes("1")),
                block.chainid,
                address(token)
            )
        );
        assertEq(token.DOMAIN_SEPARATOR(), expected);
    }

    // 3. Mint increases balance and total supply
    function testMint() public {
        uint256 amount = 100 ether;

        vm.expectEmit(true, true, false, true);
        emit UniswapV2ERC20.Transfer(address(0), bob, amount);

        token.mint(bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + amount);
    }

    // 4. Burn decreases balance and total supply
    function testBurn() public {
        uint256 amount = 200 ether;

        vm.expectEmit(true, true, false, true);
        emit UniswapV2ERC20.Transfer(alice, address(0), amount);

        token.burn(alice, amount);

        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - amount);
    }

    // 5. Transfer moves tokens
    function testTransfer() public {
        uint256 amount = 50 ether;

        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(bob), amount);
    }

    // 6. Transfer emits event
    function testTransferEmitsEvent() public {
        uint256 amount = 25 ether;

        vm.expectEmit(true, true, false, true);
        emit UniswapV2ERC20.Transfer(alice, bob, amount);

        vm.prank(alice);
        token.transfer(bob, amount);
    }

    // 7. Approve sets allowance
    function testApprove() public {
        uint256 amount = 75 ether;

        vm.prank(alice);
        token.approve(bob, amount);

        assertEq(token.allowance(alice, bob), amount);
    }

    // 8. Approve emits event
    function testApproveEmitsEvent() public {
        uint256 amount = 10 ether;

        vm.expectEmit(true, true, false, true);
        emit UniswapV2ERC20.Approval(alice, bob, amount);

        vm.prank(alice);
        token.approve(bob, amount);
    }

    // 9. transferFrom spends allowance
    function testTransferFrom() public {
        uint256 amount = 30 ether;

        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        token.transferFrom(alice, carol, amount);

        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(carol), amount);
        assertEq(token.allowance(alice, bob), 0);
    }

    // 10. transferFrom with max allowance does not decrease allowance
    function testTransferFromMaxAllowance() public {
        uint256 amount = 40 ether;

        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, carol, amount);

        assertEq(token.balanceOf(carol), amount);
        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    // 11. permit sets allowance via EIP-2612 signature
    function testPermit() public {
        uint256 amount = 60 ether;
        uint256 deadline = block.timestamp + 1 hours;
        address owner = vm.addr(aliceKey);

        token.mint(owner, INITIAL_SUPPLY);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, bob, amount, deadline, aliceKey);

        token.permit(owner, bob, amount, deadline, v, r, s);

        assertEq(token.allowance(owner, bob), amount);
        assertEq(token.nonces(owner), 1);
    }

    // 12. permit reverts when deadline has passed
    function testPermitExpired() public {
        uint256 amount = 20 ether;
        uint256 deadline = block.timestamp - 1;
        address owner = vm.addr(aliceKey);

        token.mint(owner, INITIAL_SUPPLY);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, bob, amount, deadline, aliceKey);

        vm.expectRevert("UniswapV2: EXPIRED");
        token.permit(owner, bob, amount, deadline, v, r, s);
    }

    function testPermitInvalidSignature() public {
        uint256 amount = 20 ether;
        uint256 deadline = block.timestamp + 1 hours;
        address owner = vm.addr(aliceKey);

        token.mint(owner, INITIAL_SUPPLY);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, bob, amount, deadline, aliceKey);

        vm.expectRevert("UniswapV2: INVALID_SIGNATURE");
        token.permit(carol, bob, amount, deadline, v, r, s);
    }

    function _signPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 privateKey
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(token.PERMIT_TYPEHASH(), owner, spender, value, token.nonces(owner), deadline))
            )
        );
        (v, r, s) = vm.sign(privateKey, digest);
    }
}
