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
//NOTE ensure each is updated as needed
    // Data for enumeration of held (including for sale) tokens
    uint256[] tokensHeld; // array containing each token tokenId this contract holds that has not been set for sale  //TODO ensure if held tokenId's balance is 0 => remove from arr
    uint256 tokensHeldSize; // size of tokensHeld (i.e. number of unique tokens contract holds not for sale)
    mapping(uint256 => uint256) public tokensHeldBalances; // held not-on-sale tokenid => balances

    // uint256[] tokens; // array of each existing tokenId //NOTE if I determine I need this, add to funcs necessary functionality




    constructor(string memory uri) ERC1155(uri) {}



    function getSeasonOfTokenId(uint256 tokenId) public view returns(uint16) {
        uint16 season = tokenSeason[tokenId]; //NOTE should auto revert if out of bounds
        return season;
    }


    function _tokenExists(uint256 tokenId) private view returns(bool) {
        return tokenSeason[tokenId] != 0; // tokenSeason confirms inexistence if value is 0
    }




    function mintToken(uint256 id, uint16 season, uint256 amount) external onlyOwner {
        require(season != 0, "Season cannot be 0"); // tokenSeason uses 0 value to confirm token inexistence
        if (tokenSeason[id] != 0) {
            require(tokenSeason[id] == season, "Existing id matches with a different season"); // mismatching id-season
        } else {
            tokenSeason[id] = season; // if token doesn't exist, add it and its season
        }
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
            if (tokensHeldBalances[ids[i]] == 0) { // if new token
                tokensHeld.push(ids[i]); //TODO ensure removed upon sale
                tokensHeldSize = tokensHeld.length;  //TEST should += 1 //TODO ensure removed upon sale
            }
            tokensHeldBalances[ids[i]] += amounts[i];
        }
    }





    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "Failed to withdraw ether");
    }
}