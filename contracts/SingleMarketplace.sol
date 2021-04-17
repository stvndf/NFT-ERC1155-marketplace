// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CardToken.sol";

contract SingleMarketplace is Ownable {
    CardToken cardToken;

    uint256[] public cardsForSingleSale; // all tokenIds for single sale
    uint256 public cardsForSingleSaleSize; // size of cardsForSingleSale
    mapping(uint256 => uint256) public cardsForSingleSaleBalances; // tokenId => balance (amount for single sale)

    mapping(uint256 => uint256) public cardsForSingleSalePrices; // tokenId => price
    mapping(uint16 => uint256) private defaultSeasonPrices; // season => price


    constructor(address _cardToken) { //TODO remove after putting in main contract
        cardToken = CardToken(_cardToken);
    }

    // Set wei price for tokens of a particular season
    function setTierPrice(uint16 season, uint256 price) external onlyOwner {
        defaultSeasonPrices[season] = price;
    }

    // Set wei price for a particular token (prioritised over tierPrice). Set price as 0 to reset and use season price.
    function setTokenPrice(uint256 id, uint256 price) external onlyOwner {
        cardsForSingleSalePrices[id] = price;
    }

    function setForSingleSale(uint256 id, uint256 amount) external onlyOwner {
        require(amount > 0, "Must specify an amount of at least 1");
        require(_tokenExists(id), "Cannot set inexistent token for sale");
        require(
            defaultSeasonPrices[tokenSeason[id]],
            "Card's season must have a price set"
        );
        require(tokensHeldBalances[id] >= amount);

// if cardPrice != 0 {
    set price as season price
}

        // Setting price
        uint256 memory seasonPrice = defaultSeasonPrices[tokenSeason[id]];
        setTokenPrice(id, seasonPrice);

        // Removing from tokensHeld
        tokensHeldBalances[id] -= amount;
        if (tokensHeldBalances[id] < 1) {
            tokensHeld.pop(id);
            tokensHeldSize = tokensHeld.length;
        }

        // Adding to cardsForSingleSale
        if (cardsForSingleSaleBalances[id] == 0) {
            cardsForSingleSale.push(id);
            cardsForSingleSaleSize = cardsForSingleSale.length;
        }
        cardsForSingleSaleBalances[id] += amount;
    }

    function buySingleToken(uint256 id, uint256 amount) public payable {
        require(amount > 0, "Must specify an amount of at least 1");
        require(cardsForSingleSaleBalances[id] > 0, "Token is not for sale");
        require(cardsForSingleSaleBalances[id] >= amount, "Amount specified exceeds token set for sale");
        uint memory totalPrice;
        if (cardsForSingleSalePrices[id] != 0) {
            totalPrice = cardsforSingleSalePrices[id] * amount;
        } else {
            totalPrice = defaultSeasonPrices[tokenSeason[id]];
        }
        require(msg.value == totalPrice, "Ether sent does not match price");

        // Removing from cardsForSingleSale
        cardsForSingleSaleBalances[id] -= amount;
        if (cardsForSingleSaleBalances[id] == 0) {
            cardsForSingleSale.pop(id);
            cardsForSingleSaleSize = cardsForSingleSale.length;
            cardsForSingleSalePrices[id] = 0;
        }

        safeTransferFrom(address(this), msg.sender, id, amount, "");

        //TODO consider whether amount should be limited, and if so how many

    }

    function removeFromSingleSale(uint256 id, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "Must specify an amount of at least 1");
        require(cardsForSingleSaleBalances[id] > 0, "Token is not for sale");
        require(cardsForSingleSaleBalances[id] >= amount, "Amount specified exceeds token set for sale");

        // Removing from cardsForSingleSale
        cardsForSingleSaleBalances[id] -= amount;
        if (cardsForSingleSaleBalances[id] == 0) {
            cardsForSingleSale.pop(id);
            cardsForSingleSaleSize = cardsForSingleSale.length;
            cardsForSingleSalePrices[id] = 0;
        }

        // Adding back to tokensHeld
        if (tokensHeldBalances[id] == 0) { // if new token
            tokensHeld.push(id);
	        tokensHeldSize = tokensHeld.length;
        }
        tokensHeldBalances[id] += amount;
    }

}
