// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title PolicyNFT
 * @notice ERC-721 token representing an insurance policy in the ShieldFi protocol.
 *
 * Each time a user purchases a policy through PolicyManager a PolicyNFT is minted to
 * the buyer. The token ID equals the policy ID in PolicyManager, creating a 1-to-1
 * correspondence.  Holding the NFT is purely informational / cosmetic — on-chain
 * claimability is still gated by PolicyManager state, not by token ownership.
 *
 * Design patterns used:
 *  - Access Control (MINTER_ROLE granted only to PolicyManager)
 *  - ERC721Enumerable for on-chain portfolio queries
 *
 * @dev Token URIs are returned as a base-64 encoded on-chain SVG so the frontend
 *      works without an external metadata server.
 */
contract PolicyNFT is ERC721Enumerable, AccessControl {
    // ── Roles ──────────────────────────────────────────────────────────────────
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ── Errors ─────────────────────────────────────────────────────────────────
    error ZeroAddress();
    error NotMinter();

    // ── Events ─────────────────────────────────────────────────────────────────
    /// @notice Emitted when a new policy NFT is minted.
    event PolicyMinted(address indexed to, uint256 indexed tokenId);

    // ── Constructor ────────────────────────────────────────────────────────────

    /**
     * @param admin_   Address that receives DEFAULT_ADMIN_ROLE (should be deployer / timelock).
     * @param minter_  Address that receives MINTER_ROLE (should be PolicyManager proxy).
     */
    constructor(address admin_, address minter_) ERC721("ShieldFi Policy", "SHIELD-POLICY") {
        if (admin_ == address(0) || minter_ == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MINTER_ROLE, minter_);
    }

    // ── Minting ────────────────────────────────────────────────────────────────

    /**
     * @notice Mint a policy NFT. Called by PolicyManager on every policy purchase.
     * @param to       Recipient (policy buyer).
     * @param tokenId  Policy ID from PolicyManager (1-indexed).
     */
    function mint(address to, uint256 tokenId) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert NotMinter();
        if (to == address(0)) revert ZeroAddress();
        _safeMint(to, tokenId);
        emit PolicyMinted(to, tokenId);
    }

    // ── Token URI (on-chain SVG) ───────────────────────────────────────────────

    /**
     * @notice Returns an on-chain SVG metadata URI for the given token.
     * @dev Encodes policy ID into a simple SVG so metadata works without IPFS.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400'>",
            "<rect width='400' height='400' fill='#0f172a'/>",
            "<text x='50%' y='40%' dominant-baseline='middle' text-anchor='middle' ",
            "font-size='32' fill='#38bdf8' font-family='monospace'>ShieldFi Policy</text>",
            "<text x='50%' y='58%' dominant-baseline='middle' text-anchor='middle' ",
            "font-size='48' fill='#ffffff' font-family='monospace'>#",
            Strings.toString(tokenId),
            "</text></svg>"
        ));

        string memory json = string(abi.encodePacked(
            '{"name":"ShieldFi Policy #', Strings.toString(tokenId),
            '","description":"Decentralized insurance policy issued by ShieldFi protocol.",',
            '"image":"data:image/svg+xml;utf8,', svg, '"}'
        ));

        return string(abi.encodePacked("data:application/json;utf8,", json));
    }

    // ── ERC-165 ────────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
