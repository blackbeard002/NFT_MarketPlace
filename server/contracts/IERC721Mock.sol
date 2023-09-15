//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0; 

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract IERC721Mock is ERC721
{
    constructor() ERC721("MockNFT","MNFT")
    {
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
    }
}