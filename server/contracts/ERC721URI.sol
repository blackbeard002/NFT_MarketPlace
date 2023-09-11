// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage
{
    constructor() ERC721("FC Barcelona","FCB"){}

    uint public tokenId;

    function mint(address to,string memory uri) public returns(uint)
    {
        tokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }
}