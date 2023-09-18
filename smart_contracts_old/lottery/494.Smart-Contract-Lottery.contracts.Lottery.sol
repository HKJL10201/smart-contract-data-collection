pragma solidity >=0.4.23 <0.9.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
contract LotteryContract{
    enum state {Standby,Ready,Deployed}
    uint256 stateNum;
    mapping (address => string[]) public addr;
    mapping (uint => address[]) LottoRand;
    address owner;
    address[] public addreses;
    bool ticketCheck;
    uint256 public userCount = 0;
    constructor() {
    owner = msg.sender;


    }
    function userAdd() private {
        userCount ++;
        addreses.push(msg.sender);
    }
    function TicketGen() public payable returns(address) {
        if (msg.value == 0.1 ether) {
            ticketCheck = true;
            userAdd();
        }
        require(ticketCheck = true);
        userCountView();
        return (msg.sender);
    }
    function userCountView() public view returns (uint256 UserNumber) {
        UserNumber = userCount;
        return UserNumber;
    }
    modifier adminCheck() {
        require(msg.sender == owner);
        _;

    }
       function LottoReward(RandomNumberConsumer Reward) adminCheck public {
        payable(addreses[Reward.randomResult()]).transfer(0.1 ether);
    }

}
contract RandomNumberConsumer is VRFConsumerBase{

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    address owner = msg.sender;

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
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    /**
     * Requests randomness from a user-provided seed
     ************************************************************************************
     *                                    STOP!                                         *
     *         THIS FUNCTION WILL FAIL IF THIS CONTRACT DOES NOT OWN LINK               *
     *         ----------------------------------------------------------               *
     *         Learn how to obtain testnet LINK and fund this contract:                 *
     *         ------- https://docs.chain.link/docs/acquire-link --------               *
     *         ---- https://docs.chain.link/docs/fund-your-contract -----               *
     *                                                                                  *
     ************************************************************************************/
    modifier adminConfirm() {
        require(msg.sender == owner);
        _;
    }
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash,fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;

    }

    /**
     * Withdraw LINK from this contract
     *
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function randUseCount(LotteryContract UseNum) public returns (uint){
        randomResult = randomResult % (UseNum.userCountView())+1;
        return (randomResult);

    }
    function viewRand() public view returns(uint) {
        return randomResult;
    }
    //function LottoReward(testContract Reward) adminConfirm public {
      //  payable(Reward.addreses(viewRand())).transfer(50 wei);
    //}

}