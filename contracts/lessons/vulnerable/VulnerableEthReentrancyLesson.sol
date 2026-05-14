// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title VulnerableEthReentrancyLesson
 * @notice INTENTIONALLY VULNERABLE: external `call` before balance update enables classic reentrancy drains.
 * @dev Teaching contract only — excluded from production Slither gate via `slither.config.json`.
 */
contract VulnerableEthReentrancyLesson {
    mapping(address => uint256) public balances;

    event Withdrawn(address indexed user, uint256 amount);

    receive() external payable {}

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawUnsafe(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient");
        (bool ok, bytes memory returndata) = payable(msg.sender).call{value: amount}("");
        if (!ok) {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        }
        unchecked {
            balances[msg.sender] -= amount;
        }
        emit Withdrawn(msg.sender, amount);
    }
}
