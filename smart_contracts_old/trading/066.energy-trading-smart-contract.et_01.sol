pragma solidity >=0.5.0 <0.7.0;

contract EnergyTrading {
    address creator;
    mapping (address => uint256) public balanceOf;

    constructor() public {
        creator = msg.sender;
    }

    modifier IsCreator (address _user) {
        require(_user == creator, "User not Creator!");
        _;
    }

    function SetTk(uint256 _initialSupply) public IsCreator(msg.sender) {
        balanceOf[creator] = _initialSupply;                                            // Give the creator all initial tokens
    }

    function Deposit (address _account, uint256 _amount) public IsCreator(msg.sender) {
        balanceOf[_account] += _amount;
    }

    function Withdraw (address _account, uint256 _amount) public IsCreator(msg.sender) {
        balanceOf[_account] -= _amount;
    }

    function TransferFrom(address _from, address _to, uint256 _value) public IsCreator(msg.sender) {
        require(balanceOf[_from] >= _value, "Insufficient balance.");                   // Check if the sender has enough coins
        require(balanceOf[_to] + _value >= balanceOf[_to], "Transaction overflow!");    // Check for overflows
        balanceOf[_from] -= _value;                                                     // Subtract from the sender
        balanceOf[_to] += _value;                                                       // Add the same to the recipient
    }

    /////////////
    //   bid   //
    /////////////
    struct bid_struct {
        uint256[] volumn;
        uint256[] price;
    }
    // time => type(buy/sell) => user_address => bid_struct
    mapping (string => mapping (string => mapping (address => bid_struct))) bids;

    event bid_log(address _user, string _bid_time, string _bid_type, uint256[] _volumn, uint256[] _price);

    function bid(address _user, string memory _bid_time, string memory _bid_type, uint256[] memory _volumn, uint256[] memory _price) public IsCreator(msg.sender) {
        bids[_bid_time][_bid_type][_user] = bid_struct({
            volumn: _volumn,
            price: _price
        });
        emit bid_log(_user, _bid_time, _bid_type, _volumn, _price);
    }
}
