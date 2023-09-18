// SPDX-License-Identifier: MIT  
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lottery {
    
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    
    struct LotteryStruct {
        string name;                          // Name of the lottery
        address payable owner;                // Admin address (owner)
        address payable winner;               // Winner address
        uint pricePerTicket;                  // Price per ticket
        address payable [] tickets;           // Addresses of the players (tickets)
        uint ticketsLength;                   // Tickets sold
    }
    
    uint internal currentLotteryIndex = 0;
    mapping (uint => LotteryStruct) internal lotteries;
    
    modifier onlyLotteryOwner(uint index){
         require(msg.sender == lotteries[index].owner, "You are not the owner");
        _;
    }


    function addLottery(string memory name, uint pricePerTicket) public {
        require(bytes(name).length > 0, "Name is required");
        require(pricePerTicket > 0, "pricePerTicket must be > 0");
        address payable[] memory tickets;
        lotteries[currentLotteryIndex] = LotteryStruct(name, payable(msg.sender), payable(address(0)), pricePerTicket, tickets, 0);
        currentLotteryIndex++;
    }

    function lotteriesLength() public view returns(uint) {
        return (currentLotteryIndex);
    }
    
    function getLotteryByIndex(uint index) public view returns(string memory, address payable, address payable, uint, address payable [] memory, uint, uint) {
        require(index >= 0, "index must be >= 0");
        require(index < currentLotteryIndex, "index must less than lotteriesLength");
        uint prize = getPrizeByLotteryIndex(index);
        return (lotteries[index].name, lotteries[index].owner, lotteries[index].winner, lotteries[index].pricePerTicket, lotteries[index].tickets, lotteries[index].ticketsLength, prize);
    }
    
    function buyTicketByLotteryIndex(uint index) public payable {
        require(msg.sender != lotteries[index].owner, "Owners can't play");
        require(lotteries[index].winner == address(0), "Lottery has ended");
        require(IERC20Token(cUsdTokenAddress).transferFrom(msg.sender, address(this), lotteries[index].pricePerTicket), "Transfer failed");
        lotteries[index].tickets.push(payable(msg.sender));
        lotteries[index].ticketsLength++;
    }
    

    function declareWinner(uint index) public onlyLotteryOwner(index) payable {
        require(lotteries[index].ticketsLength > 1, "Participants must be grater than 1");
        uint winnerIndex = uint(block.timestamp) % lotteries[index].ticketsLength;  // develop purposes only
        uint prize = getPrizeByLotteryIndex(index);
        require(IERC20Token(cUsdTokenAddress).transfer(lotteries[index].tickets[winnerIndex], prize), "Transfer failed");
        lotteries[index].winner = lotteries[index].tickets[winnerIndex];
    }
    
    function getPrizeByLotteryIndex(uint index) internal view returns(uint) {
        return (lotteries[index].pricePerTicket * lotteries[index].ticketsLength);
    }

}
