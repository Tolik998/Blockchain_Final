// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ProtocolTreasury
 * @notice Holds protocol fees and native gas refunds. Withdrawals are intentionally restricted to the timelock.
 */
contract ProtocolTreasury is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public immutable timelock;

    event NativeReceived(address indexed from, uint256 amount);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    error OnlyTimelock(address caller);
    error ZeroAddress();
    error ZeroAmount();

    modifier onlyTimelock() {
        if (msg.sender != timelock) revert OnlyTimelock(msg.sender);
        _;
    }

    constructor(address timelock_) {
        if (timelock_ == address(0)) revert ZeroAddress();
        timelock = timelock_;
    }

    receive() external payable {
        emit NativeReceived(msg.sender, msg.value);
    }

    function withdrawERC20(address token, address to, uint256 amount) external nonReentrant onlyTimelock {
        if (token == address(0) || to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawn(token, to, amount);
    }

    function withdrawNative(address payable to, uint256 amount) external nonReentrant onlyTimelock {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        to.sendValue(amount);
        emit Withdrawn(address(0), to, amount);
    }
}
