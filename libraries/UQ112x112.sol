// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// the library is mainly for precision math
// This is a small Solidity library (UQ112x112) that provides fixed-point math helpers for unsigned numbers with 112 fractional bits — 
// commonly used in Uniswap V2 to store price ratios with high precision.
library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}