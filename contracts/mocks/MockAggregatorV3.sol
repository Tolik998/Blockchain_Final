// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

/**
 * @title MockAggregatorV3
 * @notice Deterministic Chainlink-style feed for unit tests and local deployments.
 */
contract MockAggregatorV3 is AggregatorV3Interface {
    uint8 public override decimals = 8;
    string public override description = "Mock / USD";
    uint256 public override version = 1;

    int256 private _answer;
    uint80 private _roundId;
    uint256 private _updatedAt;

    function setAnswer(int256 answer) external {
        _answer = answer;
        unchecked {
            ++_roundId;
        }
        _updatedAt = block.timestamp;
    }

    function setStale() external {
        unchecked {
            _updatedAt = block.timestamp - 365 days;
        }
    }

    function getRoundData(
        uint80 /* roundId */
    )
        external
        view
        override
        returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }

    function latestAnswer() external view returns (int256) {
        return _answer;
    }
}
