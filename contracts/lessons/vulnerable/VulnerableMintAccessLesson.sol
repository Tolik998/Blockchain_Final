// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title VulnerableMintAccessLesson
 * @notice INTENTIONALLY VULNERABLE: missing authorization on `mint` enables supply inflation.
 */
contract VulnerableMintAccessLesson is ERC20 {
    constructor() ERC20("BadLesson", "BAD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
