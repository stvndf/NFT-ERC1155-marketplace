// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CardToken is ERC1155, ERC1155Holder, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    // Data for seasons
    mapping(uint256 => uint16) private _tokenSeason; // id => season

    // Held tokens variables (not for sale)
    EnumerableSet.UintSet private _tokensHeld; // all ids this contract holds that have not been set for sale
    mapping(uint256 => uint256) public tokensHeldBalances; // id => balance (amount held not for sale)

    // Single marketplace variables
    EnumerableSet.UintSet private _tokensForSingleSale; // all ids for single sale
    mapping(uint256 => uint256) public tokensForSingleSaleBalances; // id => balance (amount for single sale)
    mapping(uint256 => uint256) public tokensForSingleSalePrices; // id => price
    mapping(uint16 => uint256) public defaultSeasonPrices; // season => price

    // Pack marketplace variables
    EnumerableSet.UintSet private _tokensForPackSale; // all ids for pack sale //|//TEST removed when bal is 0
    mapping(uint256 => uint256) public tokensForPackSaleBalances; // id => balance (amount for single sale)
    uint256 public packPrice;

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
        require(_tokenExists(id), "Inexistent");
        return _tokenSeason[id];
    }

    // Enumeration of held tokens
    function getTokenHeldByIndex(uint256 index) public view returns (uint256) {
        return _tokensHeld.at(index);
    }

    function getTokensHeldSize() public view returns (uint256) {
        return _tokensHeld.length();
    }

    // Enumeration of tokens for single sale
    function getTokenForSingleSaleByIndex(uint256 index)
        public
        view
        returns (uint256)
    {
        return _tokensForSingleSale.at(index);
    }

    function getTokensForSingleSaleSize() public view returns (uint256) {
        return _tokensForSingleSale.length();
    }

    // Enumeration of tokens in pack
    function getTokenForPackSaleByIndex(uint256 index)
        public
        view
        returns (uint256)
    {
        return _tokensForPackSale.at(index);
    }

    function getTokensForPackSaleSize() public view returns (uint256) {
        return _tokensForPackSale.length();
    }

    // Can mint multiple tokens. Can only mint tokens for one season at a time.
    function mintTokens(
        uint256[] memory ids,
        uint16 season,
        uint256[] memory amounts
    ) external onlyOwner {
        require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
        _mintBatch(address(this), ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i] > 0);
            if (_tokenExists(ids[i])) {
                require(
                    _tokenSeason[ids[i]] == season,
                    "Existing id matches with a different season"
                ); // mismatching id-season
            } else {
                _tokenSeason[ids[i]] = season; // if token doesn't exist, add it and its season
            }
            if (tokensHeldBalances[ids[i]] == 0) {
                // if new token
                _tokensHeld.add(ids[i]); //TODO ensure removed upon setForSale
            }
            tokensHeldBalances[ids[i]] += amounts[i];
        }
    }

    // Withdraw ether from contract.
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true);
    }

    /*
        Single marketplace functionality
    */

    // Set wei price for tokens of a particular season
    function setSeasonPrice(uint16 season, uint256 price) external onlyOwner {
        require(season != 0, "Cannot set price for season 0");
        defaultSeasonPrices[season] = price;
    }

    // Set wei price for a particular token (prioritised over tierPrice). Set price as 0 to reset and use season price.
    function setTokenPrice(uint256 id, uint256 price) external onlyOwner {
        tokensForSingleSalePrices[id] = price;
    }

    function setForSingleSale(uint256 id, uint256 amount) external onlyOwner {
        require(amount > 0);
        require(_tokenExists(id), "Inexistent");
        require(
            (defaultSeasonPrices[_tokenSeason[id]] != 0) ||
                (tokensForSingleSalePrices[id] != 0),
            "Card or card's season must have a price set"
        );
        require(
            amount <= tokensHeldBalances[id],
            "Amount exceeds held amount available"
        );

        // Removing from tokensHeld
        tokensHeldBalances[id] -= amount;
        if (tokensHeldBalances[id] < 1) {
            _tokensHeld.remove(id);
        }

        // Adding to tokensForSingleSale
        if (tokensForSingleSaleBalances[id] == 0) {
            _tokensForSingleSale.add(id);
        }
        tokensForSingleSaleBalances[id] += amount;
    }

    function removeFromSingleSale(uint256 id, uint256 amount)
        external
        onlyOwner
    {
        require(_tokenExists(id), "Inexistent");
        require(amount > 0);
        require(tokensForSingleSaleBalances[id] > 0, "Not on sale");
        require(
            tokensForSingleSaleBalances[id] >= amount,
            "Amount exceeds token set for sale"
        );

        // Removing from tokensForSingleSale
        tokensForSingleSaleBalances[id] -= amount;
        if (tokensForSingleSaleBalances[id] == 0) {
            _tokensForSingleSale.remove(id);
        }

        // Adding back to tokensHeld
        if (tokensHeldBalances[id] == 0) {
            // if new token
            _tokensHeld.add(id);
        }
        tokensHeldBalances[id] += amount;
    }

    function buySingleToken(uint256 id) public payable {
        uint256 fromBalance = _balances[id][address(this)];
        require(fromBalance >= 1, "Insufficient balance for transfer");
        require(tokensForSingleSaleBalances[id] > 0, "Not on sale");
        uint256 price;
        if (tokensForSingleSalePrices[id] != 0) {
            price = tokensForSingleSalePrices[id];
        } else {
            price = defaultSeasonPrices[_tokenSeason[id]];
        }
        require(msg.value == price, "Ether sent does not match price");

        // Removing from tokensForSingleSale
        tokensForSingleSaleBalances[id] -= 1;
        if (tokensForSingleSaleBalances[id] == 0) {
            _tokensForSingleSale.remove(id);
        }

        // Transfer
        _balances[id][address(this)] = fromBalance - 1;
        _balances[id][msg.sender] += 1;
        emit TransferSingle(msg.sender, address(this), msg.sender, id, 1);
    }

    /*
        Pack marketplace functionality
    */

    // Set wei price for  packs
    function setPackPrice(uint256 price) external onlyOwner {
        packPrice = price;
    }

    function setForPackSale(uint256 id, uint256 amount) external onlyOwner {
        require(amount > 0);
        require(_tokenExists(id), "Inexistent");
        require(packPrice != 0, "Pack price must be set");
        require(
            amount <= tokensHeldBalances[id],
            "Amount exceeds held amount available"
        );

        // Removing from tokensHeld
        tokensHeldBalances[id] -= amount;
        if (tokensHeldBalances[id] < 1) {
            _tokensHeld.remove(id);
        }

        // Adding to tokensForPackSale
        if (tokensForPackSaleBalances[id] == 0) {
            _tokensForPackSale.add(id);
        }
        tokensForPackSaleBalances[id] += amount;
    }

    function removeFromPackSale(uint256 id, uint256 amount) external onlyOwner {
        require(_tokenExists(id), "Inexistent");
        require(amount > 0);
        require(tokensForPackSaleBalances[id] > 0, "Not on sale");
        require(
            tokensForPackSaleBalances[id] >= amount,
            "Amount exceeds token set for sale"
        );

        // Removing from tokensForPackSale
        tokensForPackSaleBalances[id] -= amount;
        if (tokensForPackSaleBalances[id] == 0) {
            _tokensForPackSale.remove(id);
        }

        // Adding back to tokensHeld
        if (tokensHeldBalances[id] == 0) {
            // if new token
            _tokensHeld.add(id);
        }
        tokensHeldBalances[id] += amount;
    }

    function buyPack() public payable {
        uint256 totalCardsAvailable; // sums together each id's balance
        for (uint256 i = 0; i < _tokensForPackSale.length(); i++) {
            totalCardsAvailable += tokensForPackSaleBalances[
                _tokensForPackSale.at(i)
            ];
        }
        require(msg.value == packPrice, "Ether sent does not match price");
        require(totalCardsAvailable >= 4, "At least 4 cards must be available");
        uint256 preHash = (block.number * block.difficulty) / block.timestamp;
        uint256[] memory selectedIds = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            // Equal chance of unique tokens, can be duplicate
            uint256 selectedId =
                _tokensForPackSale.at(
                    uint256(keccak256(abi.encode(preHash + i))) %
                        _tokensForPackSale.length()
                );

            tokensForPackSaleBalances[selectedId] -= 1;
            uint256 fromBalance = _balances[selectedId][address(this)];
            require(fromBalance >= 1, "Insufficient balance for transfer");
            if (tokensForPackSaleBalances[selectedId] == 0) {
                _tokensForPackSale.remove(selectedId);
            }
            // Transfer
            _balances[selectedId][address(this)] = fromBalance - 1;
            _balances[selectedId][msg.sender] += 1;

            selectedIds[i] = selectedId;
        }
        uint256[] memory counts = new uint256[](4);
        counts[0] = 1;
        counts[1] = 1;
        counts[2] = 1;
        counts[3] = 1;
        emit TransferBatch(
            msg.sender,
            address(this),
            msg.sender,
            selectedIds,
            counts
        );
    }
}
