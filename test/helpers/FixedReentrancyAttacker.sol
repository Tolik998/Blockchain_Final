// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FixedEthReentrancyLesson} from "../../contracts/lessons/fixed/FixedEthReentrancyLesson.sol";

contract FixedReentrancyAttacker {
    FixedEthReentrancyLesson public immutable target;
    uint256 public hits;

    constructor(FixedEthReentrancyLesson t) {
        target = t;
    }

    function start() external payable {
        target.deposit{value: 2 ether}();
        target.withdrawSafe(1 ether);
    }

    receive() external payable {
        if (hits == 0) {
            hits = 1;
            target.withdrawSafe(1 ether);
        }
    }
}
