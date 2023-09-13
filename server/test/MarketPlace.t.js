const { ethers } = require("hardhat");

describe("MarketPlace and ERC721URI",()=>{


  describe("MarketPlace",()=>{

    let MarketPlace;
    let marketplace;
    before(async ()=>{
      accounts= await ethers.getSigners();
      MarketPlace= await ethers.getContractFactory();
      marketplace= await MarketPlace.deploy(10);
    });

    
  });
});