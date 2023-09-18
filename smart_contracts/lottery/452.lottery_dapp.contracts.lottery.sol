pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract GLDToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Gold", "GLD") {
        _mint(msg.sender, initialSupply);
    }
}

contract lottery_dapp is VRFConsumerBaseV2{

    VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
// Rinkeby
  address vrfCoordinator =  0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
//   rinkeby
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  uint32 callbackGasLimit = 100000;

  uint16 requestConfirmations = 3;

  uint32 numWords =  2;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  constructor(uint64 subscriptionId, address _gldAddress) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    owner = payable(msg.sender);
    gldToken = GLDToken(_gldAddress);
   }
    
  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() internal onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  function getRandomWord(uint _index) internal view returns(uint256){
      return s_randomWords[_index];
  }
  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }



    uint256 ticketPrice = 1;
    address payable owner;
    uint32 public season;
    GLDToken gldToken;
    //  This  season   addresss
    mapping (uint32 => address[]) public gamblers;

    mapping (uint32 => mapping (address => bool)) isGambler;

    //      This user   in this  season buy        ticket in quantity
    mapping (address => mapping (uint32 => mapping(uint32 => uint32))) ownerTickets; 

    struct Lottery{
        uint32 result;
        uint32 winnerNum;
        uint32 winTicketNum;
        uint256 reward;
        uint256 ending;
        mapping (address => bool) winners;
        mapping (address => bool) claimed;
    }

    mapping (uint32 => Lottery) public lotterys;

    

    

   
    function _findWinners() internal{

        
        for(uint i = 0; i < gamblers[season].length; ++i)
        {
            //                      gamblers[i]  in  season buy this lottery number                       
            if(ownerTickets[gamblers[season][i]][season][lotterys[season].result] > 0)
            {
                lotterys[season].winners[gamblers[season][i]] = true;
                lotterys[season].winnerNum += 1;
                lotterys[season].winTicketNum += ownerTickets[gamblers[season][i]][season][lotterys[season].result];
            }
                
        }
        
    }

    function closeSeason() public onlyOwner{

        requestRandomWords();    
        lotterys[season].ending = block.timestamp;

    }

    function finishSeason() public onlyOwner{
        lotterys[season].result = uint32(getRandomWord(0)) % 10;
    
        _findWinners();

        season += 1;
    } 
    
    function buy(uint32 _ticket,uint32 _quantity) payable public{
        require(_quantity > 0, "Quantity must >= 0");

        // Change this condition later!
        require(lotterys[season].result == 0, "The season is closed, wait for the next!");

        // find how to approve token in this function!
        // gldToken.approve(address(this), _quantity*ticketPrice);
        gldToken.transferFrom(msg.sender,address(this),_quantity*ticketPrice);

        lotterys[season].reward += _quantity*ticketPrice;

        if(!isGambler[season][msg.sender])
        {
            isGambler[season][msg.sender] = true;
            gamblers[season].push(msg.sender);
        }
            

        ownerTickets[msg.sender][season][_ticket] += _quantity;
    }

    

    

    function claim(uint32 _season) payable public{
        Lottery storage lottery = lotterys[_season];
        require(!lottery.claimed[msg.sender],"Claimed!");
        lottery.claimed[msg.sender] = true;
        require(lottery.winners[msg.sender],"You not the one chosen in that season!");

        // Reward to user = 90% of totalreward * total win ticket of / total win ticket
        (bool sent) = gldToken.transfer(msg.sender,lottery.reward / lottery.winTicketNum * 
        ownerTickets[msg.sender][_season][lottery.result] *90/100);
        require(sent, "Failed to send Ether");

    }

    function viewTicket(uint32 _ticket) public view returns(uint32){
        return ownerTickets[msg.sender][season][_ticket];
    }

    function isWinner(uint32 _season) public view returns(bool)
    {
        return lotterys[_season].winners[msg.sender];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRewardBalance() public view returns (uint256) {
        return gldToken.balanceOf(address(this));
    }

    function viewGambler(uint32 _season) public view returns(address[] memory){
        return gamblers[_season];
    }

    function viewGamblerLen(uint32 _season) public view returns(uint256){
        return gamblers[_season].length;
    }

    function withdraw() payable onlyOwner public{
        owner.transfer(address(this).balance);
    }

}