pragma solidity >=0.4.21 <0.6.0;
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

contract makeBet {
    uint value;
    uint v;
    uint prize;
    uint public constant duration =  11 seconds;
    uint public end;
    int public P;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    address better;
    
    constructor() public {
        name = "LeoTest";
        symbol = "TEST2";
        decimals = 0;
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        end = block.timestamp + duration;
    }
    
    function TEST2(uint _totalSupply) public payable {
        require(msg.sender == 0xC5635e4904d61cD4584e3384a53545B1326bDFC7);
        balanceOf[0xC5635e4904d61cD4584e3384a53545B1326bDFC7] = _totalSupply;
        totalSupply = _totalSupply;
    }
    
    function placeBet() payable public {
        value = msg.value;
        better = msg.sender;
    }

    function () external payable {
        placeBet();

    }
    
    
    function receivePrize() payable public {
    (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        P = price / 100000000;
        require(block.timestamp >= end);
        require(msg.sender == better, "You did not place the bet");
        if (P >= 1700) {
           balanceOf[0xC5635e4904d61cD4584e3384a53545B1326bDFC7] -= value * 2;
           balanceOf[better] += value * 2;
        }
    }
    
    function returnValue() public view returns(uint) {
    return value;
    }
    
    function returnP() public view returns(int) {
    return P;
    }
    
     AggregatorV3Interface internal priceFeed;
     
     // dont forget to use proper address for mainnet. address below may only be for koven testnet

    
}

