//SPDX-License-Identifier: MIT

pragma solidity >0.7.0 <0.9.0;

import "./auction.sol";

contract auctionFactory {

    address[] public auctions;

    uint startBlock;
    uint256 endBlock;

    event auctionCreated(address auctionContract);

    address payable owner;
    constructor(){
        owner= payable(msg.sender);
        
        

    }
    function createAuction(uint timeInMinutes, uint _bidIncrement)  public {
        startBlock = block.number;
        endBlock= block.number+ calculateEndBlock(timeInMinutes);
        Auction newAuction = new Auction(owner, startBlock, endBlock, _bidIncrement);

        auctions.push(address(newAuction));

        emit auctionCreated(address(newAuction)); 
    }

    function calculateEndBlock(uint timeInMinutes) public pure returns(uint){
        return timeInMinutes*4;
    }
    
