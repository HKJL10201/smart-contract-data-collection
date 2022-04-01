pragma solidity >=0.5.0 < 0.7.0;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";


contract CoinFlip is Ownable,VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    

    struct games {
        uint256 id;
        address user;
        uint256 amount;
        uint256 coinFace;
    }   
    
    event generatedRandomNumber(
        uint256 randomNumber,
        bytes32 queryId
    );

    event playGame(uint256 id, address user, uint256 amount, uint256 coinFace,bytes32 queryId);

    event contractFunded(address user, uint256 fundAmount);

    uint256 public latestnumber;
    uint256 private ContractBalance;
    uint256 public gameId;
    mapping(bytes32 => mapping(address => bool)) public approved;
    mapping(bytes32 => games) public userGame;

    modifier costs(uint256 cost) {
        require(msg.value >= cost, "no enough ether");
        _;
    }
    
    function play(uint256 _coinFace)
        public
        payable
        costs(0.01 ether)
        returns (bool)
    {
        uint256 contractBal = ContractBalance * 2;
        require(_coinFace == 1 || _coinFace == 2, "You must be on hi or low");
        //Make sure that the balance is at least double than the bet
        require(contractBal > msg.value, "Contract cannot support this bet");

        //RANDOM NUMBER FUNCTION CALL
        update(_coinFace);
        return true;
    }

    function getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomResult = randomness % 100;
        gameLogic(randomResult, requestId);
        emit generatedRandomNumber(randomResult, requestId);
    }


    function update(uint256 _face) public payable {
        uint256 randSeed = now % 100;
        bytes32 requestId = getRandomNumber(randSeed);
        uint256 newId = gameId + 1;
        gameId = newId;        
        games memory newGame;
        newGame.id = newId;
        newGame.user = msg.sender;
        newGame.amount = msg.value;
        newGame.coinFace = _face;
        userGame[requestId] = newGame;        

        emit playGame(newId, msg.sender, msg.value, _face,requestId);
    }

    function gameLogic(uint256 randNumber, bytes32 _queryId) internal {
        uint256 _coinFace = userGame[_queryId].coinFace;
        address userAddress = userGame[_queryId].user;
        bool win = false;

        latestnumber = randNumber;
        approved[_queryId][userAddress] = true;

        //Number Higher than 51
        if (_coinFace == 1) {
            if (randNumber > 51) {
                win = true;
            } else {
                win = false;
                ContractBalance += userGame[_queryId].amount;
            }
        }
        //Number Lower than 49
        if (_coinFace == 2) {
            if (randNumber < 49) {
                win = true;
            } else {
                win = false;
                ContractBalance += userGame[_queryId].amount;
            }
        }

        if (win == true) payToWinner(_queryId);
    }

    function payToWinner(bytes32 _queryId) internal {
        address userAddress = userGame[_queryId].user;
        require(
            approved[_queryId][userAddress] == true,
            "This game was already processed"
        );
        uint256 winCalc = getPercent(userGame[_queryId].amount);
        uint256 winAmount = userGame[_queryId].amount + winCalc;
        address payable payTo = address(uint160(userAddress));
        ContractBalance = ContractBalance - winCalc;
        payTo.transfer(winAmount);
    }

    function approveNum(bytes32 _queryId) public payable returns (bool) {
        approved[_queryId][msg.sender] = true;
        return true;
    }

    function getPercent(uint256 amount) public view returns (uint256) {
        uint256 mypercent = (amount * 40) / 100;
        return mypercent;
    }

    function getContractBalance() public view returns (uint256) {
        return ContractBalance;
    }
    
    function getContractLinkBalance() public view returns (uint256) {
        return (LINK.balanceOf(address(this)));
    }

    function funding() public payable costs(10000 wei) {
        ContractBalance = ContractBalance + msg.value;
        emit contractFunded(msg.sender, msg.value);
    }

    function uintToStr(uint256 _i)
        internal
        returns (string memory _uintAsString)
    {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number != 0) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        return string(bstr);
    }
   
}
