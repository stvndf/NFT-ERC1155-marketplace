// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./SingleMarketplace.sol";
// import "./PackMarketplace.sol";

contract CardToken is ERC1155, Ownable {

    // Data for seasons
    mapping(uint256 => uint16) public tokenSeason; // id => season
//NOTE ensure each is updated as needed
    // Data for enumeration of held (including for sale) tokens
    uint256[] tokensHeld; // all tokenIds this contract holds that have not been set for sale
    uint256 tokensHeldSize; // size of tokensHeld (i.e. number of unique tokens contract holds not for sale)
    mapping(uint256 => uint256) public tokensHeldBalances; // tokenid => balances (amount held not for sale)

    // uint256[] tokens; // array of each existing tokenId //NOTE if I determine I need this, add to funcs necessary functionality

    // Single marketplace variables
    uint256[] public cardsForSingleSale; // all tokenIds for single sale
    uint256 public cardsForSingleSaleSize; // size of cardsForSingleSale
    mapping(uint256 => uint256) public cardsForSingleSaleBalances; // tokenId => balance (amount for single sale)
    mapping(uint256 => uint256) public cardsForSingleSalePrices; // tokenId => price
    mapping(uint16 => uint256) private defaultSeasonPrices; // season => price




    constructor(string memory uri) ERC1155(uri) {}



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
        if (tokenSeason[id] != 0) {
            require(tokenSeason[id] == season, "Existing id matches with a different season"); // mismatching id-season
        } else {
            tokenSeason[id] = season; // if token doesn't exist, add it and its season
        }
        _mint(address(this), id, amount, "");
        if (tokensHeldBalances[id] == 0) { // if new token
            tokensHeld.push(id);
	        tokensHeldSize = tokensHeld.length;  //TEST should += 1
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
                tokensHeld.push(ids[i]); //TODO ensure removed upon setForSale
                tokensHeldSize = tokensHeld.length;  //TEST should += 1 //TODO ensure removed upon sale
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
            cardsForSingleSale.pop(id);
            cardsForSingleSaleSize = cardsForSingleSale.length;
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
            cardsForSingleSale.pop(id);
            cardsForSingleSaleSize = cardsForSingleSale.length;
        }

        // Adding back to tokensHeld
        if (tokensHeldBalances[id] == 0) {
            // if new token
            tokensHeld.push(id);
            tokensHeldSize = tokensHeld.length;
        }
        tokensHeldBalances[id] += amount;
    }













}