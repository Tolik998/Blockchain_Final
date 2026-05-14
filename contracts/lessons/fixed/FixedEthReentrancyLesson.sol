// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title FixedEthReentrancyLesson
 * @notice Fixed counterpart to `VulnerableEthReentrancyLesson` using CEI + `ReentrancyGuard`.
 */
contract FixedEthReentrancyLesson is ReentrancyGuard {
    using Address for address payable;

    mapping(address => uint256) public balances;

    event Withdrawn(address indexed user, uint256 amount);

    error InsufficientBalance();

    receive() external payable {}

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawSafe(uint256 amount) external nonReentrant {
        uint256 bal = balances[msg.sender];
        if (bal < amount) revert InsufficientBalance();
        balances[msg.sender] = bal - amount;
        payable(msg.sender).sendValue(amount);
        emit Withdrawn(msg.sender, amount);
    }
}
