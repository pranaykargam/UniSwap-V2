// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;


import "./UniSwapV2Pair.sol";

contract UniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    // event is emitted when a new token pair is created.
    // Identify when pairs are created.
    //Track which tokens are involved.
   // Index the data for frontend applications to query.
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);


    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }


// Uniswap V2 was written in Solidity 0.5, which had no native create2 syntax → required assembly
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }


  // feeToSetter (ADMIN)
   //   ↓
  // Can call: setFeeTo(new_address) //Fee recipient address
   //   ↓
  //     Sets feeTo = new_address
  //    ↓
  // Protocol fees (0.05%) go to feeTo address

  // setFeeTo and setFeeToSetter are the two key functions that control how the protocol fee is managed,
  // but they do not directly set the fee percentage.



    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
