const { ethers } = require("hardhat");
const {expect}= require("chai");

describe("MarketPlace",()=>{

    let MarketPlace;
    let marketplace;
    before(async ()=>{
      accounts= await ethers.getSigners();
      MarketPlace= await ethers.getContractFactory("MarketPlace");
      marketplace= await MarketPlace.deploy(10);
    });
    
    describe("1:Check state variables",()=>{

      it("Check Fee Percentage:",async()=>{
        expect(await marketplace.feePercentage()).to.equal(10);
      });

      it("Check Manager",async()=>{
        expect(await marketplace.manager()).to.equal(accounts[0].address);
      });

      it("Check item ID",async()=>{
        expect(await marketplace.itemId()).to.equal(0);
      });
    });

    //List 2 NFT's
    //1st NFT is Fixed and 2nd NFt is Auction
    describe("2:Listing()",()=>{

      describe("List a fixed sale NFT:",()=>{
        
        it("List a fixed NFT:",async()=>{
          const nft='0xF59413b586C479AbC317735cAEcc00De4fADC5EC';
          const tx=await marketplace.listing(nft,2,1,0,0);
          await tx.wait();
          const [event]= await marketplace.queryFilter('NftListed');
          expect(event.args.nft).to.equal(nft);
          expect(event.args.tokenId).to.equal(2);
          expect(event.args.price).to.equal(1);
          expect(event.args.listingType).to.equal(0);
          expect(event.args.duration).to.equal(0);
        });
      });

      // describe("List a NFT for auction",()=>{

      //   it("",()=>{
          
      //   });
      // });
    });

    // describe("Direct Purchase",()=>{
      
    // });

    // describe("Auction and purchase",()=>{
      
    // });

    // describe("Transfer funds to manager",()=>{
      
    // });
});