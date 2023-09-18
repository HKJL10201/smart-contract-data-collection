pragma solidity ^0.4.23;

//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./oraclizeAPI.sol";



contract Loto is usingOraclize {
    uint constant price = 50 finney;
    uint256 constant gas = 500000;

    enum RoundState {noGame, roundStarted, timerStarted}
    //---STORAGE---//
    address private escrow;
    address public owner;

    mapping(uint256 => address) public tickets;
    uint256 public ticketsN = 0;

    mapping(address => bool) public rewardClaimable;
    uint private reward;
    uint256 public winnerN;
    //uint private jackpot;

    RoundState public currentState;

    bytes32 public oraclizeID;


    modifier ownerOnly {
        if (msg.sender != owner) 
        revert();
        _;
    }
    //---EVENTS---//
    event RoundStarted(uint256 closingBlock);
    event WinnerPicked(address winner);

    constructor(address _escrow) public {
        owner = msg.sender;
        currentState = RoundState.noGame;
        OAR = OraclizeAddrResolverI(0x5dc1E82631a4BE896333F38a8214554326C11796);
        escrow = _escrow;
    }

    function roundStart() public ownerOnly {
        require(currentState == RoundState.noGame);
        currentState = RoundState.roundStarted;
    }

    //Main and only accessible function to clients
    function EnterRound() payable public {
        require(msg.value >= price);
        require(currentState != RoundState.noGame);
        if (ticketsN <= 1000) {
            ticketsN++;
            tickets[ticketsN] = msg.sender;
            escrow.transfer((msg.value * 10)/100);
        } else {
            ticketsN++;
            tickets[ticketsN] = msg.sender;
            escrow.transfer(msg.value);
            //event maxUserReached(...);
        }
        if(ticketsN == 3) {
            setTimer();
        }
    }

    function getWin() private {
        currentState = RoundState.noGame;
        oraclize_query("WolframAlpha", strConcat("random between 1 and ", uint2str(ticketsN)),gas);
    }

    function __callback(bytes32 _oraclizeID, string _result) {
        require(msg.sender == oraclize_cbAddress());
        //better check with Query ID but nah, it'll be easier to demonstrate
        //CHECK WITH QUERY ID
        if(currentState == RoundState.timerStarted) {
            getWin();
        } else {
            winnerN = parseInt(_result);
            address winner = tickets[winnerN];
            rewardClaimable[winner] = true;
            //10% - escrow, 2% - ours
            reward = ticketsN * 44 finney;
            emit WinnerPicked(winner);
        }
    }

    function setTimer() private {
        //This could be implemented on server side
        currentState = RoundState.timerStarted;
        oraclize_query(20/*864000*/,"WolframAlpha","1 + 3", gas);
    }
    //Pull over push goes here
    function withdraw() public {
        //JUST LET HIM TAKE MONEY, JACKPOT SEPARATELLY
        require(msg.sender == tickets[winnerN]);
        require(rewardClaimable[msg.sender] == true);
        rewardClaimable[msg.sender] = false;
        msg.sender.transfer(reward);
    }

    //Just for UI sake
    function get(uint256 _ticket) public view returns (uint,uint256,address) {
        return (price,ticketsN,tickets[_ticket]);
    }

    function selfDestruct() public ownerOnly {
        selfdestruct(owner);
    }

    function () public payable {    
    }
}