// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./SingleMarketplace.sol";
// import "./PackMarketplace.sol";

contract Token is ERC1155, Ownable {
    using Address for address;

//NOTE ensure each is updated as needed
    // Data for seasons
    mapping(uint256 => uint16) public tokenSeason; // id => season
//|    mapping(uint16 => uint256[]) public seasonTokens; // season => array containing id of each token in season //NOTE this may be unnecessary as functionality can be done in reverse (tokensSeason)
//|   uint16[] public seasons; // array containing numeric name of each season //NOTE same as above
//|    uint16 public seasonsQuantity; // size of seasons (i.e. number of seasons) //NOTE same as above
//NOTE ensure each is updated as needed
    // Data for enumeration of held (including for sale) tokens
    uint256[] tokensHeld; // array containing each token id this contract holds  //TODO ensure if held tokenId's balance is 0 => remove from arr
    uint256 tokensHeldSize; // size of tokensHeld (i.e. number of unique tokens contract holds)
    mapping(uint256 => uint256) public tokensHeldBalances; // token held id => balances

    // uint256[] tokens; // array of each existing tokenId //NOTE if I determine I need this, add to funcs necessary functionality




    constructor(string memory uri) ERC1155(uri) {}



    function getSeasonOfTokenId(uint256 tokenId) public view returns(uint16) {
        uint16 season = tokenSeason[tokenId]; //NOTE should auto revert if out of bounds
        return season;
    }

    // //NOTE: only include this if decide to use seasonTokens
    // function getTokenIdBySeason(uint16 season, uint16 index) public view returns(uint256) {
    //     uint256 tokenId = seasonTokens[season][index];
    //     return tokenId;
    // }


    // function _addTokenIdToSeason(uint256 tokenId, uint16 season) private {
    //     require(tokenSeason == 0, "tokenId already exists"); // tokenSeason confirms inexistence if value is 0
    //     //_tokenIdExists
    //     tokenSeason[tokenId] = season;
    //     // seasonTokens //TODO if decide to use this, set it (may also need extra global array/mapping to be set to enumerate)
    // }
    // function _tokenIdExists(uint256 tokenId) private {
    //     require(tokenSeason == 0, "tokenId already exists"); // tokenSeason confirms inexistence if value is 0
    // }




    function mintToken(uint256 id, uint16 season, uint256 amount) external onlyOwner {
        require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
        if (tokenSeason[id] != 0) {
            require(tokenSeason[id] == season, "Existing id matches with a different season"); // mismatching id-season
        } else {
            tokenSeason[id] = season; // if token doesn't exist, add it and its season
        }
        //TODO If I decide to use it: add to seasonTokens (+ seasons + seasonsQuantity)
        if (tokensHeldBalances[id] == 0) { // if new token
            tokensHeld.push(id); //TODO ensure removed upon sale
	        tokensHeldSize = tokensHeld.length;  //TEST should += 1 //TODO ensure removed upon sale
        }
        tokensHeldBalances[id] += amount;
        _mint(address(this), id, amount, "");

    }

    function mintTokenBatch(uint256 ids, uint16 seasons, uint256 amounts) external onlyOwner {
        // Overriding default _mintBatch to avoid a superfluous loop
        _mintBatch(address(this), ids, amounts, "", seasons);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data, uint16 season) internal override {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
            if (tokenSeason[ids[i]] != 0) {
                require(tokenSeason[ids[i]] == season, "Existing id matches with a different season"); // mismatching id-season
            } else {
                tokenSeason[ids[i]] = season; // if token doesn't exist, add it and its season
            }
            if (tokensHeldBalances[ids[i]] == 0) { // if new token
            tokensHeld.push(ids[i]); //TODO ensure removed upon sale
	        tokensHeldSize = tokensHeld.length;  //TEST should += 1 //TODO ensure removed upon sale
        }
            tokensHeldBalances[ids[i]] += amounts[i];
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private override
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }




    function withdraw() external onlyOwner {}
}