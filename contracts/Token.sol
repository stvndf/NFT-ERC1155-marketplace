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

        _mint(address(this), id, amount, "");

        if (tokensHeldBalances[id] == 0) { // if new token
            tokensHeld.push(id); //TODO ensure removed upon sale
	        tokensHeldSize = tokensHeld.length;  //TEST should += 1 //TODO ensure removed upon sale
        }
        tokensHeldBalances[id] += amount;
    }


    function mintTokenBatch(uint256[] memory ids, uint16 season, uint256[] memory amounts) external onlyOwner {
        // Can only mint tokens for one particular season
        _mintBatch(address(this), ids, amounts, "");
        for (uint i = 0; i < ids.length; i++) {
            require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
            if (tokenSeason[ids[i]] != 0) {
                require(tokenSeason[ids[i]] == season, "Existing id matches with a different season"); // mismatching id-season
            } else {
                tokenSeason[ids[i]] = season; // if token doesn't exist, add it and its season
            }
            //TODO If I decide to use it: add to seasonTokens (+ seasons + seasonsQuantity)
            if (tokensHeldBalances[ids[i]] == 0) { // if new token
                tokensHeld.push(ids[i]); //TODO ensure removed upon sale
                tokensHeldSize = tokensHeld.length;  //TEST should += 1 //TODO ensure removed upon sale
            }
            tokensHeldBalances[ids[i]] += amounts[i];
        }
    }





    function withdraw() external onlyOwner {}
}