// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./SingleMarketplace.sol";
import "./PackMarketplace.sol";

contract Token is Ownable {

    // TODO add ERC1155 enumeration

    mapping (uint16 => uint256) public seasonTokens; // season => tokenId
    mapping(uint256 => uint16) public tokenSeason;

    function _exists(uint256 id) private {

    }

    function getSeasonByTokenId(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
    }

    function mintToken(uint256 id, uint256 amount, uint16 season) external onlyOwner {
        if (_exists(id))
        // add to seasonTokens
        _mint(address(this), id, amount);
    }

    function mintTokenBatch() external onlyOwner {

    }

    function withdraw() external onlyOwner {}
}