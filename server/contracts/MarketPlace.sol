//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0; 

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MarketPlace
{

    enum ListingType
    {
        Fixed,
        Auction
    }

    uint public fee;
    address public manager;
    uint public itemId;

    struct item
    {
        IERC721 nft;
        address payable seller; 
        uint itemId;
        uint tokenId;
        uint price;
        uint duration;
        address highestBidder;
        ListingType listingType;
        bool sold;
    } 

    event NftListed
    (
        address nft,
        uint tokenId,
        uint price,
        ListingType listingType,
        uint duration
    );

    event NftPurchased
    (
        address nft,
        address seller,
        address buyer,
        uint tokenId,
        uint price,
        uint sellerFees
    );

    //itemId=>Item
    mapping(uint=>item) public items;

    constructor(uint _fee)
    {
        fee=_fee;
        manager=msg.sender;
    }

    //listing a NFT
    function listing(IERC721 nft,uint tokenId,uint price,ListingType listingType,uint duration) public 
    {
        itemId++;

        items[itemId]=item
        (
            nft,
            payable(msg.sender), //seller address
            itemId,
            tokenId,
            price*1 ether,
            block.timestamp+duration,
            address(0), //buyer address
            listingType,
            false
        );

        nft.approve(address(this), tokenId);

        emit NftListed
        (
            address(nft), 
            tokenId, 
            price, 
            listingType, 
            duration
        );
    }

    //check the curent highest bid 
    function currentHighestBid(uint _itemId) public view returns(uint)
    {
        return items[_itemId].price;
    }

    //place bids
    function bid(uint _bid,uint _itemId) public 
    {
        require(items[_itemId].listingType==ListingType.Auction,"This item is under direct purchase");
        require(block.timestamp<items[_itemId].duration,"Auction has ended");
        require(_bid*1 ether>items[_itemId].price,"Your bid is lower than the current highest bid");
        items[_itemId].price=_bid*1 ether;
        items[_itemId].highestBidder=msg.sender;
    }

    //purchase the NFT
    function purchase(uint _itemId) public payable 
    {
        require(_itemId<=itemId && _itemId>0,"Item doesn't exist");
        require(items[_itemId].sold==false,"NFT isn't for purchase");
        require(msg.value==items[_itemId].price,"Send the correct amount");
        
        //transfer money to the nft seller
        uint sellerFees; 
        sellerFees=((100-fee)/100)*msg.value;
        items[_itemId].seller.transfer(sellerFees);
        items[_itemId].sold=true;

        //transfer the nft to the new owner
        items[_itemId].nft.transferFrom(items[_itemId].seller,msg.sender,items[_itemId].tokenId);
        
        emit NftPurchased
        (
            address(items[_itemId].nft),
             items[_itemId].seller, 
             msg.sender, 
             items[_itemId].tokenId, 
             items[_itemId].price, 
             sellerFees
        );
    }
}