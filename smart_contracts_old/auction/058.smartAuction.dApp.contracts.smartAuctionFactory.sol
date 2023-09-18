pragma solidity ^0.5.3;
import "./englishAuction.sol";
import "./vickeryAuction.sol";

//factory contract: used to deploy new smart auctions
//NOTE: remix's default gas limit is not enough (at least 4000000 gas needed)
contract smartAuctionFactory{
    address[] public englishAuctions;
    address[] public vickeryAuctions;
    address payable owner;
    
    event newEnglishAuctionEvent(address addr); //notify the deployment of a new english auction
    event newVickeryAuctionEvent(address addr); //notify the deployment of a new vickery auction

    constructor() public {
        owner = msg.sender;
    }
    
    //deploy english
    function deployEnglishAuction(uint _reservePrice, uint _buyOutPrice, uint _unchallegedLength, uint _increment) public returns (address) {
        englishAuction auction = new englishAuction(msg.sender, _reservePrice, _buyOutPrice, _unchallegedLength, _increment);
        address addr = address(auction);

        englishAuctions.push(addr);
        emit newEnglishAuctionEvent(addr);

        return addr;
    }
    
    //deploy vickery
    function deployVickeryAuction(uint _reservePrice, uint _deposit, uint _bidCommitLength, uint _bidWithdrawLength, uint _bidOpeningLength) public returns (address) {
        vickeryAuction auction = new vickeryAuction(msg.sender, _reservePrice, _deposit, _bidCommitLength, _bidWithdrawLength, _bidOpeningLength);
        address addr = address(auction);

        vickeryAuctions.push(addr);
        emit newVickeryAuctionEvent(addr);

        return addr;
    }

    //used to destroy the auction factory
    function closeFactory() public{
        require(msg.sender == owner, "you are not the owner of the auction factory!");

        selfdestruct(owner);
    }

    function getOwner() public view returns(address){
        return owner;
    }

    function getEnglishAuctions() public view returns(address[] memory){
        return englishAuctions;
    }

    function getVickeryAuctions() public view returns(address[] memory){
        return vickeryAuctions;
    }
}
