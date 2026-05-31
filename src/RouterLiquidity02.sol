
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24; 


import "./UniSwapV2Factory.sol";
import {UniSwapV2Library} from "../libraries/UniSwapV2Library.sol";
import "./interfaces/IUniswapV2Pair.sol";


// @title UniswapV2Router02 — Remove Liquidity — 
contract UniSwapV2Router02 {
    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }


//removeLiquidity returns both tokens as ERC20s
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = UniSwapV2Library.pairFor(factory, tokenA, tokenB);
        safeTransferFrom(pair, msg.sender, pair, liquidity);
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = UniSwapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
    }

    // removeLiquidityETH returns one asset as actual ETH (since ETH is the native token, not an ERC20)

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB) {
        address pair = UniSwapV2Library.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address pair = UniSwapV2Library.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}
