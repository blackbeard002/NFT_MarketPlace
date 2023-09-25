const { ethers } = require("hardhat");
const {expect}= require("chai");

describe("MarketPlace",()=>{

    let marketplace;
    let nft;
    beforeEach(async ()=>{
      accounts= await ethers.getSigners();
      const MarketPlace= await ethers.getContractFactory("MarketPlace");
      marketplace= await MarketPlace.deploy(10);

      const NFTContract = await ethers.getContractFactory('IERC721Mock');
      nft = await NFTContract.deploy();
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
    describe("2:Listing",()=>{   
        it("List a NFT for fixed price:",async()=>{
          const tx=await marketplace.listing(nft.address,2,1,0,0);
          await tx.wait();
          const [event]= await marketplace.queryFilter('NftListed');
          expect(event.args.nft).to.equal(nft.address);
          expect(event.args.tokenId).to.equal(2);
          expect(event.args.price).to.equal(1);
          expect(event.args.listingType).to.equal(0);
          expect(event.args.duration).to.equal(0);
          const a=await marketplace.items(1);
          expect(a[2]).to.equal(1);
        });

        it("List a NFT for Auction",async()=>{
          const tx2=await marketplace.listing(nft.address,2,5,1,180);
          await tx2.wait();
          const [event2]= await marketplace.queryFilter('NftListed');
          expect(event2.args.nft).to.equal(nft.address);
          expect(event2.args.tokenId).to.equal(2);
          expect(event2.args.price).to.equal(5);
          expect(event2.args.listingType).to.equal(1);
          expect(event2.args.duration).to.equal(180);
          const a=await marketplace.items(1);
          expect(a[2]).to.equal(1);
        });
    });

    describe("3:Direct Purchase",()=>{
      it("Make a direct Purchase",async()=>{
          const tx=await marketplace.listing(nft.address,1,1,0,0);
          await tx.wait();
          await nft.connect(accounts[0]).approve(marketplace.address,1);
          const val=ethers.utils.parseEther("1");
          const tx2=await marketplace.connect(accounts[1]).purchase(1,{value:val});
          await tx2.wait();
          const [event]= await marketplace.queryFilter('NftPurchased');
          expect(event.args.nft).to.equal(nft.address);
          expect(event.args.seller).to.equal(accounts[0].address);
          expect(event.args.buyer).to.equal(accounts[1].address);
          expect(event.args.tokenId).to.equal(1);
          expect(event.args.price).to.equal(ethers.utils.parseEther("1"));
      });
    });

    describe("4:Auction and purchase",()=>{
      it("Place Bids and purchase",async()=>{
        const tx=await marketplace.listing(nft.address,1,5,1,5);
        await tx.wait();
        await nft.connect(accounts[0]).approve(marketplace.address,1);
        //place bids
        await marketplace.connect(accounts[1]).bid(6,1);
        await expect(await marketplace.currentPrice(1)).to.equal(ethers.utils.parseEther("6"));
        await expect(marketplace.connect(accounts[2]).bid(1,1)).to.be.revertedWith("Your bid is lower than the current highest bid");
        await marketplace.connect(accounts[2]).bid(10,1);
        await expect(await marketplace.currentPrice(1)).to.equal(ethers.utils.parseEther("10"));
        await expect(marketplace.connect(accounts[2]).purchase(1,{value:ethers.utils.parseEther("10")})).to.be.revertedWith("Auction hasn't ended");
        //delays time
        await new Promise(resolve => setTimeout(resolve, 5 * 1000));
        //purchase
        const buy=await marketplace.connect(accounts[2]).purchase(1,{value:ethers.utils.parseEther("10")});
        await buy.wait();
        const [event]= await marketplace.queryFilter('NftPurchased');
        expect(await nft.ownerOf(1)).to.equal(event.args.buyer);
      });
    });

    describe("5:Transfer funds to manager",()=>{
      it("Transfer funds",async()=>{
          const tx=await marketplace.listing(nft.address,1,10,0,0);
          await tx.wait();
          await nft.connect(accounts[0]).approve(marketplace.address,1);
          const val=ethers.utils.parseEther("10");
          const tx2=await marketplace.connect(accounts[1]).purchase(1,{value:val});
          await tx2.wait();
          await expect(marketplace.connect(accounts[1]).checkManagerBalance()).to.be.revertedWith("Only the manaer can call this");
          const managerBalanceBefore=BigInt(await ethers.provider.getBalance(accounts[0].address));
          const contractManagerBalance=await marketplace.checkManagerBalance();
          await expect(contractManagerBalance).to.be.equal(managerBalanceBefore);
          const [event]= await marketplace.queryFilter('NftPurchased');
          const tx3=await marketplace.connect(accounts[0]).transferToManager();
          await tx3;
          const managerBalanceAfter=BigInt(await ethers.provider.getBalance(accounts[0].address));
          await expect(managerBalanceAfter).to.be.greaterThan(managerBalanceBefore);
      });
    }); 
});
