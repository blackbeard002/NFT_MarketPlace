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

    uint public feePercentage;
    address payable public manager;
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
        uint finalPrice
    );

    modifier onlyOwner
    {
        require(msg.sender==manager,"Only the manaer can call this");
        _;
    }

    //itemId=>Item
    mapping(uint=>item) public items;

    constructor(uint _fee)
    {
        feePercentage=_fee;
        manager=payable(msg.sender);
    }

    //listing a NFT
    //input the duration as zero if it's a fixed price listing
    //approve() should be called from ERC721 contract where the NFT was minted
    function listing(IERC721 nft,uint tokenId,uint price,ListingType listingType,uint duration) public 
    {
        require(msg.sender==nft.ownerOf(tokenId),"You're not the owner of the NFT");

            itemId++;
            
            items[itemId]=item
            (
                nft,
                payable(msg.sender), //seller address
                itemId,
                tokenId,
                (price*1 ether),
                block.timestamp+duration,
                address(0), //highest bidder
                listingType,
                false //item's status, whether it's sold or not 
            );

            emit NftListed
            (
                address(nft), 
                tokenId, 
                price, 
                listingType, 
                duration
            );
    }

    //returns price of each nft after the seller price is added along with the marketplace fee
    function currentPrice(uint _itemId) public view returns(uint)
    {
        return items[_itemId].price;
    }

    //place bids
    //bids placed should be whole numbers and in ethers
    function bid(uint _bid,uint _itemId) public 
    {
        require(items[_itemId].listingType==ListingType.Auction,"This item is under direct purchase");
        require(block.timestamp<items[_itemId].duration,"Auction has ended");
        require(_bid*1 ether>items[_itemId].price,"Your bid is lower than the current highest bid");
        items[_itemId].price=_bid*1 ether;
        items[_itemId].highestBidder=msg.sender;
    }

    //check highest bidder
    function highestBidder(uint itemID) public view returns(address)
    {
        return items[itemID].highestBidder;
    }

    //purchase the NFT
    function purchase(uint _itemId) public payable 
    {
        require(_itemId<=itemId && _itemId>0,"Item doesn't exist");
        require(block.timestamp>items[_itemId].duration,"Auction hasn't ended");
        require(items[_itemId].sold==false,"NFT already sold");
        require(msg.value==items[_itemId].price,"Send the correct amount");
        
        //transfer money to the nft seller
        uint finalPrice;
        finalPrice= ((100-feePercentage)*(items[_itemId].price))/100;
        items[_itemId].seller.transfer(finalPrice);
        items[_itemId].sold=true;

        //transfer the nft to the new owner
        if(items[_itemId].listingType==ListingType.Fixed)
        {
            items[_itemId].nft.transferFrom(items[_itemId].seller,msg.sender,items[_itemId].tokenId);
        }
        else
        {
            require(items[_itemId].highestBidder==msg.sender);
            items[_itemId].nft.transferFrom(items[_itemId].seller,msg.sender,items[_itemId].tokenId);
        }
        
        emit NftPurchased
        (
            address(items[_itemId].nft),
            items[_itemId].seller, 
            msg.sender, 
            items[_itemId].tokenId, 
            items[_itemId].price,
            finalPrice
        );
    }

    //send money to the manager
    function transferToManager() public onlyOwner
    { 
        manager.transfer(address(this).balance);
    }

    function checkManagerBalance() public view onlyOwner returns(uint)
    {
        return manager.balance; 
    }
}