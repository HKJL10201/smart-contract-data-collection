
pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public price;
    // cap ether each account could purchase with
    uint public capacity;
    uint8 public decimals = 18;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint amount, bool isContribution);

    event ErrorCapacity(address backer, string message, uint amount);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    constructor(
        address ifSuccessfulSendTo,
        uint tokenForEachEther,
        uint256 tokenCapacityOfEachAccount,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        price = tokenForEachEther;
        capacity = tokenCapacityOfEachAccount * 10 ** uint256(decimals);
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable {
        // if (balanceOf[msg.sender] >= capacity) {
        //     revert("The account has already exceeded capacity");
        // }

        // if (capacity - balanceOf[msg.sender] < msg.value) {
        //     revert("Insufficient token available");
        // }
        require(balanceOf[msg.sender] < capacity, "The account has already exceeded capacity");
        require(capacity - balanceOf[msg.sender] >= msg.value, "Insufficient token available");
        // require(balanceOf[msg.sender] <= capacity, "The account has already exceeded capacity of " + capacity);
        // require((capacity - balanceOf[msg.sender]) * price < msg.value * 1 ether, "Maximum " + (capacity - balanceOf[msg.sender]) * price);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;

        tokenReward.transfer(msg.sender, (amount * price));
        // tokenReward.transfer(msg.sender, 20 * 10 ** 18);
        emit FundTransfer(msg.sender, amount, true);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {        
    //   TKN memory tkn;
    //   tkn.sender = _from;
    //   tkn.value = _value;
    //   tkn.data = _data;
    //   uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
    //   tkn.sig = bytes4(u);

      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }

}
