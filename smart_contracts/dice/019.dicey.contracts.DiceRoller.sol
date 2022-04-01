// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/*
    This is my first smart contract that I created to learn Solidity on my own and away from tutorials. My goals
    are to learn different aspects of smart contract development by doing my own research which helps with my overall
    understanding. I wanted to create something that would be minimal so I can complete it fairly quickly and push it to the community
    for feedback. I also want to expand beyond the smart contract and create the user interface, unit tests, then replicate this
    across other blockchains, etc. Final goal is to document my learning process and progress to possibly help others explore
    the web 3.0 ecosystem.
    
    I also find the use of a blockchain dice roller smart contract ingeniously ironic in its ridiculousness for this platform.
    
    The main APIs here are:
    hasRolled which will be used by a user interface to store values generated from the front end code to the block chain.
    rollDice which ends up making use of Chainlink's VRF to get a random value.
    rollDiceFast just uses some blockchain data to simulate a psuedo random number
    
    I am also keeping a history of all the dice rolls ever made. This will be good for a future experiment on how to retrieve data from a 
    deployed contract when I want to update it without lossing data.
*/
/*
    https://docs.chain.link/docs/vrf-contracts/
    Testnet LINK are available from https://faucets.chain.link/kovan
    Kovan deploy values:
    const contract = await contractFactory.deploy(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRFCOORDINATOR
        0xa36085F69e2889c224210F603D836748e7dC0088, // LINK
        0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,  // KEYHASH
        100000000000000000 // FEE = 0.1 LINK
    ); 
*/
contract DiceRoller is VRFConsumerBase, Ownable {
    /// Using these values to manipulate the random value on each die roll.
    /// The goal is an attempt to further randomize randomness for each die rolled.
    /**
    * 77194726158210796949047323339125271902179989777093709359638389338608753093290
    * 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    * 10101010101010101010101010101...
    */
    uint constant MODIFIER_VALUE_1 = 77194726158210796949047323339125271902179989777093709359638389338608753093290;

    /**
    * 38597363079105398474523661669562635951089994888546854679819194669304376546645
    * 0x55555555555555555555555555555555555555555555555555555555555555555
    * 0101010101...
    */
    uint constant MODIFIER_VALUE_2 = 38597363079105398474523661669562635951089994888546854679819194669304376546645;
    uint8 constant MAX_DICE_ALLOWED = 10;
    uint8 constant MAX_DIE_SIZE_ALLOWED = 100;
    int8 private constant ROLL_IN_PROGRESS = 42;

    bytes32 private chainLinkKeyHash;
    uint256 private chainlinkVRFFee;

    struct DiceRollee {
        address rollee;
        uint timestamp; /// When the die were rolled
        uint256 randomness; /// Stored to help verify/debug results
        uint8 numberOfDie; /// 1 = roll once, 4 = roll four die
        uint8 dieSize; // 6 = 6 sided die, 20 = 20 sided die
        int8 adjustment; /// Can be a positive or negative value
        int16 result; /// Result of all die rolls and adjustment. Can be negative because of a negative adjustment.
        /// Max value can be 1000 (10 * 100 sided die rolled)
        bool hasRolled; /// Used in some logic tests
        uint8[] rolledValues; /// array of individual rolls. These can only be positive.
    }

    /**
    * Mapping between the requestID (returned when a request is made), 
    * and the address of the roller. This is so the contract can keep track of 
    * who to assign the result to when it comes back.
    */
    mapping(bytes32 => address) private rollers;

    /// stores the roller and the state of their current die roll.
    mapping(address => DiceRollee) private currentRoll;

    /// users can have multiple die rolls
    mapping (address => DiceRollee[]) rollerHistory;

    /// keep list of user addresses for fun/stats
    /// can iterate over them later.
    address[] internal rollerAddresses;

    /// Emit this when either of the rollDice functions are called.
    /// Used to notify soem front end that we are waiting for response from
    /// chainlink VRF.
    event DiceRolled(bytes32 indexed requestId, address indexed roller);

    /// Emitted when fulfillRandomness is called by Chainlink VRF to provide the random value.
    event DiceLanded(
        bytes32 indexed requestId, 
        address indexed roller, 
        uint8[] rolledvalues, 
        int8 adjustment, 
        int16 result
        );

    // Allow up to 10 dice to be rolled.
    modifier validateNumberOfDie(uint8 _numberOfDie) {
        require(_numberOfDie <= MAX_DICE_ALLOWED, "Too many dice!");
        _;
    }

    modifier validateDieSize(uint8 _dieSize) {
        require(_dieSize <= MAX_DIE_SIZE_ALLOWED, "100 sided die is the max allowed.");
        _;
    }
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        chainLinkKeyHash = _keyHash;
        chainlinkVRFFee = _fee;
    }

    /**
    * When the contract is killed, make sure to return all unspent tokens back to my wallet.
    */
    function kill() external onlyOwner {
        LINK.transfer(owner(), getLINKBalance());
        selfdestruct(payable(owner()));
    }

    /// Used to perform specific logic based on if user has rolled previoulsy or not.
    function hasRolledOnce(address _member) public view returns(bool isIndeed) {
        return (rollerHistory[_member].length > 0);
    }

    /**
    * Called by the front end if user wants to use the front end to 
    * generate the random values. We just use this to store the result of the roll on the blockchain.
    *
    * @param _numberOfDie how many dice are rolled
    * @param _dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
    * @param _adjustment the modifier to add after all die have been rolled. Can be negative.
    * @param _result can be negative if you have a low enough dice roll and larger negative adjustment.
    * Example, rolled 2 4 sided die with -4 adjustment.
    */
    function hasRolled(uint8 _numberOfDie, uint8 _dieSize, int8 _adjustment, int8 _result) 
        public 
        validateNumberOfDie(_numberOfDie)
        validateDieSize(_dieSize)
    {
        DiceRollee memory diceRollee = DiceRollee(
                msg.sender, 
                block.timestamp,
                0, 
                _numberOfDie, 
                _dieSize, 
                _adjustment, 
                _result, 
                true,
                new uint8[](_numberOfDie)
                );
        currentRoll[msg.sender] = diceRollee;
        rollerHistory[msg.sender].push(diceRollee);

        /// Only add roller to this list once.
        if (! hasRolledOnce(msg.sender)) {
            rollerAddresses.push(msg.sender);
        }
    }
    

    /**
     * @notice Requests randomness from Chainlink.
     *
     * @param _numberOfDie how many dice are rolled
     * @param _dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
     * @param _adjustment the modifier to add after all die have been rolled. Can be negative.
     */
    function rollDice(
        uint8 _numberOfDie, 
        uint8 _dieSize, 
        int8 _adjustment) 
        public 
        validateNumberOfDie(_numberOfDie)
        validateDieSize(_dieSize)
        returns (bytes32 requestId) 
    {
        /// checking LINK balance to make sure we can call the Chainlink VRF.
        require(LINK.balanceOf(address(this)) >= chainlinkVRFFee, "Not enough LINK to pay fee");

        /// Call to Chainlink VRF for randomness
        requestId = requestRandomness(chainLinkKeyHash, chainlinkVRFFee);
        rollers[requestId] = msg.sender;

        DiceRollee memory diceRollee = DiceRollee(
                msg.sender, 
                block.timestamp,
                0, 
                _numberOfDie, 
                _dieSize, 
                _adjustment, 
                ROLL_IN_PROGRESS, 
                false,
                new uint8[](_numberOfDie)
                );
 
        /// Only add roller to this list once.
        if (! hasRolledOnce(msg.sender)) {
            rollerAddresses.push(msg.sender);
            diceRollee.hasRolled = true;
        }

        currentRoll[msg.sender] = diceRollee;
        emit DiceRolled(requestId, msg.sender);
    }


    /**
     * @notice Uses psuedo randomness based on blockchain data. This function is used to 
     * compare speed of getting some sort of randomness straight from the blockchain 
     * instead of waiting for Chainlink VRF to return a random value.
     *
     * @param _numberOfDie how many dice are rolled
     * @param _dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
     * @param _adjustment the modifier to add after all die have been rolled. Can be negative.
     */
    function rollDiceFast(
        uint8 _numberOfDie, 
        uint8 _dieSize, 
        int8 _adjustment) 
        public 
        validateNumberOfDie(_numberOfDie)
        validateDieSize(_dieSize)
        returns (bytes32 requestId) 
    {
        /// Simple hacky way to generate a requestId.
        requestId = keccak256(abi.encodePacked(chainLinkKeyHash, block.timestamp));
        rollers[requestId] = msg.sender;
        DiceRollee memory diceRollee = DiceRollee(
                msg.sender, 
                block.timestamp,
                0, 
                _numberOfDie, 
                _dieSize, 
                _adjustment, 
                ROLL_IN_PROGRESS, 
                false,
                new uint8[](_numberOfDie)
                );

        /// Only add roller to this list once.
        if (! hasRolledOnce(msg.sender)) {
            rollerAddresses.push(msg.sender);
            diceRollee.hasRolled = true;
        }

        currentRoll[msg.sender] = diceRollee;
        emit DiceRolled(requestId, msg.sender);
        uint256 randomness = (block.timestamp + block.difficulty);
        fulfillRandomness(requestId, randomness);
    }

    /// returns historic data for specific address/user
    function getUserRolls(address _address) public view returns (DiceRollee[] memory) {
        return rollerHistory[_address];
    }

    /// How many times someone rolled.
    function getUserRollsCount(address _address) public view returns (uint) {
        return rollerHistory[_address].length;
    }

    /// only allow the contract owner (me) to access this.
    function getAllUsers() public view returns (address[] memory) {
        return rollerAddresses;
    }

    function getAllUsersCount() public view returns (uint) {
        return rollerAddresses.length;
    }

    function getRoller(address _roller) view public returns (DiceRollee memory) {
        return currentRoll[_roller];
    }

    function getBalance() view public returns (uint256) {
        return address(this).balance;
    }

    // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
    // https://medium.com/coinmonks/get-token-balance-for-any-eth-address-by-using-smart-contracts-in-js-b603fef2061c
    // returns the amount of LINK tokens this contract has.
    function getLINKBalance() view public onlyOwner returns (uint256) {
       return LINK.balanceOf(address(this));
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number
     * to this contract.
     *
     * This is the core function where we try to generate random values from a single
     * random value provided. For each die to roll, we use the passed inrandom value
     * perform some calculation on it to generate a new "random" value that we then
     * perform the mod on. Goal is if you are rolling x 10 sided die, each roll 
     * generates a different value.
     *
     * @param _requestId bytes32
     * @param _randomness The random result returned by the oracle
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        /// Associate the random value with the roller based on requestId.
        DiceRollee storage rollee = currentRoll[rollers[_requestId]];
        delete rollee.rolledValues;
        rollee.randomness = _randomness;

        uint counter; /// Tracks how many die have been rolled.
        int calculatedValue;

        /// iterate over each die to be rolled and calc the value based on a sort of randomness.
        while (counter < rollee.numberOfDie) {
            uint curValue;
            uint v = _randomness;
            
            /**
             *   This code attempts to force enough chnge in the passed random value
             *   so that can look like it generates multiple random numbers.
            */
            if (counter % 2 == 0) {
                if (counter > 0){
                    v = _randomness / (100*counter);
                }
                /// Add 1 to prevent returning 0
                curValue = addmod(v, MODIFIER_VALUE_1, rollee.dieSize) + 1;
            } else {
                if (counter > 0) {
                    v = _randomness / (99*counter);
                }
                /// Add 1 to prevent returning 0
                curValue = mulmod(v, MODIFIER_VALUE_2, rollee.dieSize) + 1;
            }

            calculatedValue += int(curValue);
            rollee.rolledValues.push( uint8(curValue) );
            ++counter;
        }// while

        calculatedValue += rollee.adjustment;
        rollee.result = int16(calculatedValue);
        address rollerAdress = rollers[_requestId];
        currentRoll[rollerAdress] = rollee;
        rollerHistory[rollerAdress].push(rollee);
        emit DiceLanded(_requestId, rollee.rollee, rollee.rolledValues, rollee.adjustment, rollee.result);
    }


    function isOwner() internal view virtual returns (bool) {
        return msg.sender == owner();
    }
}
