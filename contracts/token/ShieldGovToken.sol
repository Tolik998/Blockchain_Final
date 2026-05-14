// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title ShieldGovToken
 * @notice Governance token with voting checkpoints and EIP-2612 permits. Minting is restricted to the timelock executor.
 */
contract ShieldGovToken is ERC20, ERC20Permit, ERC20Votes {
    address public immutable minter;

    error NotMinter();
    error ZeroAddress();

    constructor(address minter_, address initialReceiver, uint256 initialSupply)
        ERC20("ShieldFi Governance", "sSHIELD")
        ERC20Permit("ShieldFi Governance")
    {
        if (minter_ == address(0)) revert ZeroAddress();
        minter = minter_;
        if (initialSupply != 0) {
            if (initialReceiver == address(0)) revert ZeroAddress();
            _mint(initialReceiver, initialSupply);
        }
    }

    /**
     * @notice Mint new voting tokens. Only callable by the configured minter (expected: TimelockController).
     */
    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert NotMinter();
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(Nonces, ERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}
