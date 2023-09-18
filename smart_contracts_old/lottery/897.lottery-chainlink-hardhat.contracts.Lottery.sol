pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    IERC20 private lotteryToken;
    address private feeWallet;
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    uint256 public lotteryId;
    address[] public players;
    // .01 ETH
    uint256 public MINIMUM = 1000000000000000;

    struct LotteryValue {
        address player;
        uint64 number1;
        uint64 number2;
        uint64 number3; 
    }

    LotteryValue[] public _lotteryValue;

    uint256 public winnerNumber1;
    uint256 public winnerNumber2;
    uint256 public winnerNumber3;

    address[] public firstWinners;
    address[] public secondWinners;

    uint8 public winnerType;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint[] public randomNumber;
    mapping (bytes32 => uint) public requestIds;
    uint256 public randomResult;
    uint256 public balance;
    uint8 public randomNumberId;

    address public winner;
    event RequestedRandomness(bytes32 requestId);
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor(address _vrfCoordinator,
                address _link,
                bytes32 _keyHash,
                uint _fee) 
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        ) public
    {
        keyHash = _keyHash;
        fee = _fee;
        
        lotteryId = 1;
        randomNumberId = 1;
        lottery_state = LOTTERY_STATE.CLOSED;
    }
    /** 
     * Requests randomness from a user-provided seed
     */
     
    function getRandomNumber(uint256 userProvidedSeed) public {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        bytes32 _requestId = requestRandomness(keyHash, fee, userProvidedSeed);
        requestIds[_requestId] = lotteryId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        if (randomNumberId == 1) {
            winnerNumber1 = randomness % 26;
        } else if (randomNumberId == 2) {
            winnerNumber2 = randomness % 26;
        } else if (randomNumberId == 3) {
            winnerNumber3 = randomness % 26;
        }
        randomNumberId++;
        lotteryId = requestIds[requestId];
        randomNumber.push(randomness);
    }
    
    /**
     * Withdraw LINK from this contract
     * 
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(feeWallet)), "Unable to transfer");
    }

    function enter(uint64 _number1, uint64 _number2, uint64 _number3) public {
        require(lottery_state == LOTTERY_STATE.OPEN, "New lottery is not started");
        uint256 allowance = lotteryToken.allowance(msg.sender, feeWallet);
        require(allowance >= MINIMUM, "Check the token allowance");
        lotteryToken.transferFrom(msg.sender, feeWallet, MINIMUM);

        players.push(msg.sender);

        require(_number1 >= 0 && _number1 < 26, "Lottery Number should be between 0 and 25.");
        require(_number2 >= 0 && _number2 < 26, "Lottery Number should be between 0 and 25.");
        require(_number3 >= 0 && _number3 < 26, "Lottery Number should be between 0 and 25.");

        _lotteryValue.push(LotteryValue(msg.sender, _number1, _number2, _number3));
    } 
    
    function start_new_lottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function end_lottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery hasn't even started!");
        // add a require here so that only the oracle contract can
        // call the fulfill alarm method
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        lotteryId = lotteryId + 1;
    }

    function pickWinner() public {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");

        uint tokenAmount = lotteryToken.balanceOf(feeWallet);
        uint jackPotAmount = ( tokenAmount / 1000000 ) * 923077;

        getRandomNumber(block.timestamp + lotteryId + 1);
        getRandomNumber(block.timestamp + lotteryId + 2);
        getRandomNumber(block.timestamp + lotteryId + 3);

        for (uint i = 0; i < players.length; i++)
        {
            winnerType = 0;
            if (_lotteryValue[i].number1 == winnerNumber1)
            {
                winnerType++;
            }
            if (_lotteryValue[i].number2 == winnerNumber2)
            {
                winnerType++;
            }
            if (_lotteryValue[i].number3 == winnerNumber3)
            {
                winnerType++;
            }
            if (winnerType == 2) {
                secondWinners.push(_lotteryValue[i].player);
            } else if (winnerType == 3) {
                firstWinners.push(_lotteryValue[i].player);
            }
        }

        if (secondWinners.length > 0) {
            uint secondAmount = ( jackPotAmount / 100 ) * 20;
            sendFunds( secondWinners, secondAmount / secondWinners.length );

            if (firstWinners.length > 0) {
                uint firstAmount = jackPotAmount - secondAmount;
                sendFunds( firstWinners, firstAmount / firstWinners.length );
            }
        } else if (firstWinners.length > 0) {            
            sendFunds( firstWinners, jackPotAmount / firstWinners.length );
        }
        
        balance = lotteryToken.balanceOf(feeWallet);
        
        for (uint i = 0; i < players.length; i++) {
            delete _lotteryValue[i];
        }
        players = new address[](0);
        firstWinners = new address[](0);
        secondWinners = new address[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        //this kicks off the request and returns through fulfill_random
    }

    function sendFunds( address[] memory receivers, uint amount ) public {
        for (uint i = 0; i < receivers.length; i++) {
            address a = receivers[i];
            uint160 b = uint160(a);
            address receiver = address(b);
            // LINK.transferFrom(address(this), receivers[i], amount);
            lotteryToken.transferFrom(feeWallet, receiver, amount);
        }
    }

    function get_players() public view returns (address[] memory) {
        return players;
    }

    function get_lottery_value(uint index) public view returns (uint64, uint64, uint64) {
        return ( _lotteryValue[index].number1, _lotteryValue[index].number2, _lotteryValue[index].number3 );
    }
    
    function get_pot() public view returns(uint256){
        return address(this).balance;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        lotteryToken = IERC20(_tokenAddress);
    }

    function setFeeWallet(address _feeWalletAddress) public onlyOwner {
        feeWallet = _feeWalletAddress;
    }
}
