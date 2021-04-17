// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CardToken is ERC1155, Ownable {

    using EnumerableSet for EnumerableSet.UintSet;

    // Data for seasons
    mapping(uint256 => uint16) public tokenSeason; // id => season
//NOTE ensure each is updated as needed

    // Held tokens variables (not for sale)
    EnumerableSet.UintSet private _tokensHeld; // all tokenIds this contract holds that have not been set for sale
    mapping(uint256 => uint256) public tokensHeldBalances; // tokenid => balances (amount held not for sale)

    // uint256[] tokens; // array of each existing tokenId //NOTE if I determine I need this, add to funcs necessary functionality

    // Single marketplace variables
    EnumerableSet.UintSet private _cardsForSingleSale; // all tokenIds for single sale
    uint256 private _cardsForSingleSaleSize; // size of cardsForSingleSale
    mapping(uint256 => uint256) public cardsForSingleSaleBalances; // id => balance (amount for single sale)
    mapping(uint256 => uint256) public cardsForSingleSalePrices; // id => price
    mapping(uint16 => uint256) public defaultSeasonPrices; // season => price




    constructor(string memory uri) ERC1155(uri) {}

    function getTokensHeldByIndex(uint256 index) public view returns(uint256) {
        return EnumerableSet.at(_tokensHeld, index);
    }
    function getTokensHeldSize() public view returns(uint256) {
        return EnumerableSet.length(_tokensHeld);
    }

    function getSeasonOfTokenId(uint256 tokenId) public view returns(uint16) {
        uint16 season = tokenSeason[tokenId]; //NOTE should auto revert if out of bounds
        return season;
    }

    function _tokenExists(uint256 tokenId) private view returns(bool) {
        return tokenSeason[tokenId] != 0; // tokenSeason confirms inexistence if value is 0
    }

    // Mint a particular token
    function mintToken(uint256 id, uint16 season, uint256 amount) external onlyOwner {
        require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
        if (tokenSeason[id] != 0) { //TEST that all minted tokens have season
            require(tokenSeason[id] == season, "Existing id matches with a different season"); // mismatching id-season
        } else {
            tokenSeason[id] = season; // if token doesn't exist, add it and its season
        }
        _mint(address(this), id, amount, "");
        if (tokensHeldBalances[id] == 0) { // if new token
            EnumerableSet.add(_tokensHeld, id);  //TEST should += 1
        }
        tokensHeldBalances[id] += amount;
    }

    // Mint multiple tokens. Can only mint tokens for one season at a time.
    function mintTokenBatch(uint256[] memory ids, uint16 season, uint256[] memory amounts) external onlyOwner {
        _mintBatch(address(this), ids, amounts, "");
        for (uint i = 0; i < ids.length; i++) {
            require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
            if (tokenSeason[ids[i]] != 0) {
                require(tokenSeason[ids[i]] == season, "Existing id matches with a different season"); // mismatching id-season
            } else {
                tokenSeason[ids[i]] = season; // if token doesn't exist, add it and its season
            }
            if (tokensHeldBalances[ids[i]] == 0) { // if new token
                EnumerableSet.add(_tokensHeld, ids[i]); //TODO ensure removed upon setForSale
            }
            tokensHeldBalances[ids[i]] += amounts[i];
        }
    }

    // Withdraw ether from contract.
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "Failed to withdraw ether");
    }


    /*
        Single marketplace functionality
    */

    // For enumeration of cards for single sale
    function getCardsForSingleSaleByIndex(uint256 index) public view returns(uint256) {
        return EnumerableSet.at(_cardsForSingleSale, index);
    }
    function getCardsForSingleSaleSize() public view returns(uint256) {
        return EnumerableSet.length(_cardsForSingleSale);
    }

    // Set wei price for tokens of a particular season
    function setSeasonPrice(uint16 season, uint256 price) external onlyOwner {
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
            (defaultSeasonPrices[tokenSeason[id]] != 0) ||
                (cardsForSingleSalePrices[id] != 0),
            "Card or card's season must have a price set"
        );
        require(tokensHeldBalances[id] >= amount);

        // Removing from tokensHeld
        tokensHeldBalances[id] -= amount;
        if (tokensHeldBalances[id] < 1) {
            EnumerableSet.remove(_tokensHeld, id);
        }

        // Adding to cardsForSingleSale
        if (cardsForSingleSaleBalances[id] == 0) {
            EnumerableSet.add(_cardsForSingleSale, id);
        }
        cardsForSingleSaleBalances[id] += amount;
    }

    function buySingleToken(uint256 id) public payable {
        require(cardsForSingleSaleBalances[id] > 0, "Token is not for sale");
        uint256 price;
        if (cardsForSingleSalePrices[id] != 0) {
            price = cardsForSingleSalePrices[id];
        } else {
            price = defaultSeasonPrices[tokenSeason[id]];
        }
        require(msg.value == price, "Ether sent does not match price");

        // Removing from cardsForSingleSale
        cardsForSingleSaleBalances[id] -= 1;
        if (cardsForSingleSaleBalances[id] == 0) {
            EnumerableSet.remove(_cardsForSingleSale, id);
        }

        safeTransferFrom(address(this), msg.sender, id, 1, "");
    }

    function removeFromSingleSale(uint256 id, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "Must specify an amount of at least 1");
        require(cardsForSingleSaleBalances[id] > 0, "Token is not for sale");
        require(
            cardsForSingleSaleBalances[id] >= amount,
            "Amount specified exceeds token set for sale"
        );

        // Removing from cardsForSingleSale
        cardsForSingleSaleBalances[id] -= amount;
        if (cardsForSingleSaleBalances[id] == 0) {
            EnumerableSet.remove(_cardsForSingleSale, id);
        }

        // Adding back to tokensHeld
        if (tokensHeldBalances[id] == 0) { // if new token
            EnumerableSet.add(_tokensHeld, id);
        }
        tokensHeldBalances[id] += amount;
    }













}