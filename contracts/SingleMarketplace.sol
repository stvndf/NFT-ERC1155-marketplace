// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SingleMarketplace is Ownable {

    uint256[] public cardsForSale;

    function setForSingleSale() external onlyOwner {}

    function removeFromSingleSale() external onlyOwner {}

}