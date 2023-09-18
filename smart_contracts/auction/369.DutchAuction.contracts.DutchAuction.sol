// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DutchAuction {
    address constant  _tokenContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3; //0xe7f1725e7734ce288f8367e1bb143e90bb3f0512 on deployment
    address payable owner;
    uint256 startDate;
    uint256 endDate;
    uint256 rate;
    uint72 totalSupply;
    uint32 price;
    uint32 resPrice;

    enum ContractState {OPEN, CLOSED}
    ContractState contractstate;
  

    constructor(uint256 _TotalHours, uint32 _startingPrice, uint32 _resPrice, uint72 _totalSupply){
        require(_TotalHours >= 12, "Auction should last for at least 12h");
        startDate = block.timestamp;
        endDate = block.timestamp + _TotalHours * 3600;
        price = _startingPrice;
        resPrice = _resPrice;
        totalSupply = _totalSupply;
        rate = (price - resPrice)/((endDate - startDate)/3600);
        owner = payable(msg.sender);
        contractstate = ContractState.OPEN;
        
    }
    
    struct newReservetion {
        address payable sender;
        uint256 currentPrice;
        uint72 ammount;
        
    }
    
    newReservetion[] public newRes;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this");
        _;
    }

    modifier conditionmet() {
        bool con = false;
        if(totalSupply == 0 || endDate <= block.timestamp){
            con = true;
        }
        require(con, "Requirements not yet met");
        _;
    }

    function transferTokensToContract() external onlyOwner{
        IERC20(_tokenContract).transferFrom(msg.sender, address(this),totalSupply);
    }

    function priceManager() public view returns (uint256 ){
        uint256 currentPrice = price - rate *((block.timestamp - startDate)/3600); 
        if(currentPrice < resPrice ) {currentPrice = resPrice;}
        return currentPrice;
    }
    
    function makeBid(uint72 _totalTokens) external payable {
        require(totalSupply > 0,"All tokens Are Sold ");
        require(contractstate == ContractState.OPEN,"Auction is finished");
        require(endDate > block.timestamp,"Auction time ended");
        uint256 currentPrice = priceManager();
        require(msg.value == _totalTokens * currentPrice * 10**9,"Not the right amount of funds" );
        if(_totalTokens<totalSupply){
            newRes.push(newReservetion(payable(msg.sender), currentPrice, _totalTokens));
            totalSupply = totalSupply - _totalTokens;
        }else if(_totalTokens == totalSupply){
            newRes.push(newReservetion(payable(msg.sender), currentPrice, _totalTokens));
            totalSupply = 0;
        }else if(_totalTokens > totalSupply){
            newRes.push(newReservetion(payable(msg.sender), currentPrice, totalSupply));
            uint256 value = newRes[newRes.length -1 ].currentPrice * (_totalTokens - totalSupply) * 10**9;
            payable(msg.sender).call{value: value};
            totalSupply = 0;
        }

        if(totalSupply == 0 ){
            sendFunds(currentPrice);
        } 
    }
    
    function sendFunds(uint256 _endingPrice) public payable conditionmet {
        for(uint72 i =0; i<newRes.length; i++){
            address payable sender = newRes[i].sender;
            IERC20(_tokenContract).transfer(newRes[i].sender , newRes[i].ammount); 
            uint256 refund = (newRes[i].currentPrice - _endingPrice) * newRes[i].ammount * 10**9;
            sender.transfer(refund);
        }  
        contractstate = ContractState.CLOSED;        
    }


    function balance() external view returns (uint){
        uint256 balances =  IERC20(_tokenContract).balanceOf(msg.sender);
        return balances;
    }

    function contractBalance() external view returns(uint){
        uint256 balanceContract =  IERC20(_tokenContract).balanceOf(address(this));
        return balanceContract;
    }
    
    
    function getRate() external view returns (uint) {
        return rate;
    }

    function getSupply() external view returns (uint){
        return totalSupply;
    }

    
    
    
    
}
