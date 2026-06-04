// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../v2-core/UniSwapV2Factory.sol";
import {UniswapV2Pair} from "../v2-core/UniSwapV2Pair.sol";
import {UniswapV2Router02 as RouterSwap} from "../v2-periphery/RouterSwap.sol";
import {FeeOnTransfer as RouterFeeOnTransfer} from "../v2-periphery/RouterFeeOnTransfer.sol";
import {UniSwapV2Library} from "../libraries/UniSwapV2Library.sol";

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 value) external {
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external virtual returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            allowance[from][msg.sender] = currentAllowance - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MockFeeOnTransferERC20 is MockERC20 {
    uint256 public constant FEE_BPS = 100;

    constructor() MockERC20("Fee Token", "FEE") {}

    function _transfer(address from, address to, uint256 value) internal override {
        uint256 fee = value * FEE_BPS / 10_000;
        uint256 received = value - fee;

        balanceOf[from] -= value;
        balanceOf[to] += received;
        totalSupply -= fee;

        emit Transfer(from, to, received);
        emit Transfer(from, address(0), fee);
    }
}

contract MockWETH is MockERC20 {
    constructor() MockERC20("Wrapped Ether", "WETH") {}

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint256 value) external {
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);

        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "WETH: ETH_TRANSFER_FAILED");
    }
}

contract RouterMainTest is Test {
    UniswapV2Factory private factory;
    RouterSwap private routerSwap;
    RouterFeeOnTransfer private routerFee;
    MockERC20 private tokenA;
    MockERC20 private tokenB;
    MockFeeOnTransferERC20 private feeToken;
    MockWETH private weth;

    address private alice = makeAddr("alice");

    function setUp() public {
        factory = new UniswapV2Factory(address(this));
        weth = new MockWETH();
        routerSwap = new RouterSwap(address(factory), address(weth));
        routerFee = new RouterFeeOnTransfer(address(factory), address(weth));
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        feeToken = new MockFeeOnTransferERC20();

        vm.deal(alice, 100 ether);
    }

    function testFactoryCreatePairAndLibraryPairForMatch() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));
        address computedPair = UniSwapV2Library.pairFor(address(factory), address(tokenA), address(tokenB));

        assertEq(pair, computedPair);
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
        assertEq(factory.getPair(address(tokenB), address(tokenA)), pair);
        assertEq(factory.allPairsLength(), 1);
    }

    function testPairMintStoresInitialReserves() public {
        address pair = _addLiquidity(tokenA, tokenB, 100 ether, 100 ether);
        (uint112 reserveA, uint112 reserveB, ) = UniswapV2Pair(pair).getReserves();

        assertEq(reserveA, 100 ether);
        assertEq(reserveB, 100 ether);
        assertGt(UniswapV2Pair(pair).balanceOf(address(this)), 0);
    }

    function testRouterSwapExactTokensForTokens() public {
        _addLiquidity(tokenA, tokenB, 100 ether, 100 ether);
        tokenA.mint(alice, 10 ether);

        address[] memory path = _path(address(tokenA), address(tokenB));
        uint256 expectedOut = _getAmountOut(10 ether, 100 ether, 100 ether);

        vm.startPrank(alice);
        tokenA.approve(address(routerSwap), 10 ether);
        uint256[] memory amounts = routerSwap.swapExactTokensForTokens(
            10 ether,
            expectedOut,
            path,
            alice,
            block.timestamp
        );
        vm.stopPrank();

        assertEq(amounts[0], 10 ether);
        assertEq(amounts[1], expectedOut);
        assertEq(tokenB.balanceOf(alice), expectedOut);
    }

    function testFeeOnTransferRouterUsesActualAmountReceived() public {
        _addLiquidity(feeToken, tokenB, 100 ether, 100 ether);
        feeToken.mint(alice, 10 ether);

        address[] memory path = _path(address(feeToken), address(tokenB));
        uint256 amountReceivedByPair = 9.9 ether;
        uint256 expectedOut = _getAmountOut(amountReceivedByPair, 100 ether, 100 ether);

        vm.startPrank(alice);
        feeToken.approve(address(routerFee), 10 ether);
        routerFee.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            10 ether,
            expectedOut,
            path,
            alice,
            block.timestamp
        );
        vm.stopPrank();

        assertEq(tokenB.balanceOf(alice), expectedOut);
    }

    function testFeeOnTransferRouterRejectsInvalidPath() public {
        address[] memory invalidPath = new address[](1);
        invalidPath[0] = address(tokenA);

        vm.prank(alice);
        vm.expectRevert("UniswapV2Router: INVALID_PATH");
        routerFee.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether,
            0,
            invalidPath,
            alice,
            block.timestamp
        );
    }

    function _addLiquidity(
        MockERC20 token0,
        MockERC20 token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (address pair) {
        pair = factory.getPair(address(token0), address(token1));
        if (pair == address(0)) {
            pair = factory.createPair(address(token0), address(token1));
        }

        token0.mint(pair, amount0);
        token1.mint(pair, amount1);
        UniswapV2Pair(pair).mint(address(this));
    }

    function _path(address token0, address token1) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = token0;
        path[1] = token1;
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
