
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// Create our smart contract
contract BettingGame is VRFConsumerBase {

    uint256 internal fee;
    uint256 public randomResult;

    //Network: Rinkeby
    address constant VRFC_address = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B; // VRF Coordinator
    address constant LINK_address = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // LINK token

    //Seed for random generation of bet outcome
    uint256 constant half =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    //Keyhash is the public key for which randomness is generated
    bytes32 internal constant keyHash =
        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;

    uint256 public gameId;
    uint256 public lastGameId;
    address payable public admin;
    mapping(uint256 => Game) public games;
    
    // checks who is able to call certain functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not the admin");
        _;
    }

    modifier onlyVRFC() {
        require(msg.sender == VRFC_address, "only VRFC can call this function");
        _;
    }

    struct Game {
        uint256 id;
        uint256 bet;
        uint256 amount;
        address payable player;
    }
    
    event Result(
        uint256 id,
        uint256 bet,
        uint256 amount,
        address player,
        uint256 winAmount,
        uint256 randomResult,
        uint256 time
    );
    event Withdraw(address admin, uint256 amount);
    event Received(address indexed sender, uint256 amount);

    
    constructor() public VRFConsumerBase(VRFC_address, LINK_address) {
        fee = 0.1 * 10**18; // 0.1 LINK
        admin = msg.sender;
    }
    
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        verdict(randomResult);
    }
    
    function game(uint256 bet) public payable returns (bool) {
        //0 is low, refers to 1-3  dice values
        //1 is high, refers to 4-6 dice values
        require(bet <= 1, "bet must be 0 or 1");
    
        //vault balance must be at least equal to msg.value
        require(
            address(this).balance >= msg.value,
            "Error, insufficent vault balance"
        );
    
        //each bet has unique id
        games[gameId] = Game(gameId, bet, msg.value, msg.sender);
    
        //increase gameId for the next bet
        gameId = gameId + 1;
    
        //where we talk to chainlink
        getRandomNumber();
    
        return true;
    }
    
    // send the payout to the winners
    function verdict(uint256 random) public payable onlyVRFC {
        //check bets from latest betting round, one by one
        for (uint256 i = lastGameId; i < gameId; i++) {
            //reset winAmount for current user
            uint256 winAmount = 0;
    
            //if user wins, then receives 2x of their betting amount
            if (
                (random >= half && games[i].bet == 1) ||
                (random < half && games[i].bet == 0)
            ) {
                winAmount = games[i].amount * 2;
                games[i].player.transfer(winAmount);
            }
            emit Result(
                games[i].id,
                games[i].bet,
                games[i].amount,
                games[i].player,
                winAmount,
                random,
                block.timestamp
            );
        }
        //save current gameId to lastGameId for the next betting round
        lastGameId = gameId;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}
