// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title GasOptimizedMath
 * @notice Benchmark helpers: OpenZeppelin `Math.mulDiv` vs a hand-written Yul path for identical results on supported inputs.
 */
library GasOptimizedMath {
    function premiumMulDivSolidity(uint256 coverage, uint256 rateBps, uint256 duration, uint256 year) internal pure returns (uint256) {
        return Math.mulDiv(coverage * uint256(rateBps), uint256(duration), 10_000 * year);
    }

    /**
     * @dev Computes `(coverage * rateBps * duration) / (10000 * year)` using `mulmod`/`mul` assembly for the product.
     *      For capstone benchmarking, inputs are constrained so the product fits in 256 bits (test suite enforces bounds).
     */
    function premiumMulDivYul(uint256 coverage, uint256 rateBps, uint256 duration, uint256 year) internal pure returns (uint256 result) {
        assembly {
            let prod := mul(coverage, mul(rateBps, duration))
            let denom := mul(10000, year)
            result := div(prod, denom)
        }
    }
}
