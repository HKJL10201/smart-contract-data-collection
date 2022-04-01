// solium-disable linebreak-style
pragma solidity >=0.5.0 <0.7.0;

contract EnergyTradingLite {
    address creator;
    mapping(address => uint256) public balanceOf;

    constructor() public {
        creator = msg.sender;
    }

    modifier IsCreator(address _user) {
        require(_user == creator, "User not Creator!");
        _;
    }

    function SetTk(uint256 _initialSupply) public IsCreator(msg.sender) {
        balanceOf[creator] = _initialSupply; // Give the creator all initial tokens
    }

    function Deposit(address _account, uint256 _amount)
        public
        IsCreator(msg.sender)
    {
        balanceOf[_account] += _amount;
    }

    function Withdraw(address _account, uint256 _amount)
        public
        IsCreator(msg.sender)
    {
        balanceOf[_account] -= _amount;
    }

    function TransferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public IsCreator(msg.sender) {
        require(balanceOf[_from] >= _value, "Insufficient balance."); // Check if the sender has enough coins
        require(
            balanceOf[_to] + _value >= balanceOf[_to],
            "Transaction overflow!"
        ); // Check for overflows
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
    }

    /////////////
    //   bid   //
    /////////////

    struct bid_struct {
        uint256[] volume;
        uint256[] price;
    }
    // time => type(buy/sell) => user_address => bid_struct
    mapping(string => mapping(string => mapping(address => bid_struct))) bids;

    event bid_log(
        address _user,
        string _bid_time,
        string _bid_type,
        uint256[] _volume,
        uint256[] _price
    );

    function bid(
        address _user,
        string memory _bid_time,
        string memory _bid_type,
        uint256[] memory _volume,
        uint256[] memory _price
    ) public IsCreator(msg.sender) {
        bids[_bid_time][_bid_type][_user] = bid_struct({
            volume: _volume,
            price: _price
        });
        emit bid_log(_user, _bid_time, _bid_type, _volume, _price);
    }

    event get_log(uint256[] _volume, uint256[] _price);

    function getBid(
        address _user,
        string memory _bid_time,
        string memory _bid_type
    ) public view returns (uint256[] memory, uint256[] memory) {
        bid_struct memory the_bid = bids[_bid_time][_bid_type][_user];
        return (the_bid.volume, the_bid.price);
    }

    /////////////
    //  match  //
    /////////////

    // event that logs matched result
    event matched_log(
        string _event_time,
        uint256[] _matched_volume,
        uint256[] _matched_price,
        string _matched_buyers,
        string _matched_sellers
    );

    function match_bids(
        string memory _bid_time,
        uint256[] memory _volumes,
        uint256[] memory _prices,
        string memory _buyers,
        string memory _sellers
    )
        public
        IsCreator(msg.sender)
    {
        // emit matched result
        emit matched_log(
            _bid_time,
            _volumes,
            _prices,
            _buyers,
            _sellers
        );
    }


    //////////////////
    //  settlement  //
    //////////////////

    event settlement_log(
        uint256 _volume,
        uint256 _price,
        address _buyer,
        address _seller,
        uint256 _generated_vol,
        uint256 _amount
    );

    function settlement(
        uint256 _volume,
        uint256 _price,
        address _buyer,
        address _seller,
        uint256 _generated_vol,
        uint256 _amount
    ) public IsCreator(msg.sender) {
        TransferFrom(_buyer, _seller, _amount);
        emit settlement_log(
            _volume,
            _price,
            _buyer,
            _seller,
            _generated_vol,
            _amount
        );
    }

    ///////////////////////
    //  demand response  //
    ///////////////////////

    event dr_log(string _data_str);

    function DR_result(
        string memory _data_str
    ) public IsCreator(msg.sender) {
         emit dr_log(
            _data_str
        );
    }
}
