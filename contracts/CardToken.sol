// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
// import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CardToken is ERC1155, ERC1155Holder, Ownable {
    // contract CardToken is ERC1155, ERC1155Receiver, Ownable {

    using EnumerableSet for EnumerableSet.UintSet;

    // Data for seasons
    mapping(uint256 => uint16) private _tokenSeason; // id => season
    //NOTE ensure each is updated as needed

    // Held tokens variables (not for sale)
    EnumerableSet.UintSet private _tokensHeld; // all ids this contract holds that have not been set for sale
    mapping(uint256 => uint256) private _tokensHeldBalances; // id => balance (amount held not for sale)

    // uint256[] tokens; // array of each existing tokenId //NOTE if I determine I need this, add to funcs necessary functionality

    // Single marketplace variables
    EnumerableSet.UintSet private _cardsForSingleSale; // all tokenIds for single sale
    mapping(uint256 => uint256) public cardsForSingleSaleBalances; // id => balance (amount for single sale)
    mapping(uint256 => uint256) public cardsForSingleSalePrices; // id => price
    mapping(uint16 => uint256) public defaultSeasonPrices; // season => price

    constructor(string memory uri) ERC1155(uri) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _tokenExists(uint256 id) private view returns (bool) {
        return _tokenSeason[id] != 0; // tokenSeason confirms inexistence if value is 0
    }

    /*
        Getters
    */

    // Obtain seaon token belongs to
    function getSeasonOfTokenId(uint256 id) public view returns (uint16) {
        require(_tokenExists(id), "Token does not exist");
        return _tokenSeason[id];
    }

    // Enumeration of held tokens
    function getTokenHeldByIndex(uint256 index) public view returns (uint256) {
        return _tokensHeld.at(index);
    }

    function getTokensHeldSize() public view returns (uint256) {
        return _tokensHeld.length();
    }

    function getBalanceOfTokenId(uint256 id) public view returns (uint256) {
        return _tokensHeldBalances[id];
    }

    // Enumeration of tokens for single sale
    function getCardForSingleSaleByIndex(uint256 index)
        public
        view
        returns (uint256)
    {
        return _cardsForSingleSale.at(index);
    }

    function getCardsForSingleSaleSize() public view returns (uint256) {
        return _cardsForSingleSale.length();
    }

    // Mint a particular token
    function mintToken(
        uint256 id,
        uint16 season,
        uint256 amount
    ) external onlyOwner {
        require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
        require(amount > 0, "Must mint at least 1 of the token");
        if (_tokenSeason[id] != 0) {
            //TEST that all minted tokens have season
            require(
                _tokenSeason[id] == season,
                "Existing id matches with a different season"
            ); // mismatching id-season
        } else {
            _tokenSeason[id] = season; // if token doesn't exist, add it and its season
        }
        _mint(address(this), id, amount, "");
        if (_tokensHeldBalances[id] == 0) {
            // if new token
            _tokensHeld.add(id); //TEST should += 1
        }
        _tokensHeldBalances[id] += amount;
    }

    // Mint multiple tokens. Can only mint tokens for one season at a time.
    function mintTokenBatch(
        uint256[] memory ids,
        uint16 season,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(address(this), ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
            require(amounts[i] > 0, "Must mint at least 1 of the token");
            if (_tokenSeason[ids[i]] != 0) {
                require(
                    _tokenSeason[ids[i]] == season,
                    "Existing id matches with a different season"
                ); // mismatching id-season
            } else {
                _tokenSeason[ids[i]] = season; // if token doesn't exist, add it and its season
            }
            if (_tokensHeldBalances[ids[i]] == 0) {
                // if new token
                _tokensHeld.add(ids[i]); //TODO ensure removed upon setForSale
            }
            _tokensHeldBalances[ids[i]] += amounts[i];
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
            (defaultSeasonPrices[_tokenSeason[id]] != 0) ||
                (cardsForSingleSalePrices[id] != 0),
            "Card or card's season must have a price set"
        );
        require(_tokensHeldBalances[id] >= amount);

        // Removing from tokensHeld
        _tokensHeldBalances[id] -= amount;
        if (_tokensHeldBalances[id] < 1) {
            _tokensHeld.remove(id);
        }

        // Adding to cardsForSingleSale
        if (cardsForSingleSaleBalances[id] == 0) {
            _cardsForSingleSale.add(id);
        }
        cardsForSingleSaleBalances[id] += amount;
    }

    function buySingleToken(uint256 id) public payable {
        require(cardsForSingleSaleBalances[id] > 0, "Token is not for sale");
        uint256 price;
        if (cardsForSingleSalePrices[id] != 0) {
            price = cardsForSingleSalePrices[id];
        } else {
            price = defaultSeasonPrices[_tokenSeason[id]];
        }
        require(msg.value == price, "Ether sent does not match price");

        // Removing from cardsForSingleSale
        cardsForSingleSaleBalances[id] -= 1;
        if (cardsForSingleSaleBalances[id] == 0) {
            _cardsForSingleSale.remove(id);
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
            _cardsForSingleSale.remove(id);
        }

        // Adding back to tokensHeld
        if (_tokensHeldBalances[id] == 0) {
            // if new token
            _tokensHeld.add(id);
        }
        _tokensHeldBalances[id] += amount;
    }
}
