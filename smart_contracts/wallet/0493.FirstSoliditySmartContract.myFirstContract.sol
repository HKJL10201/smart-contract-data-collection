pragma solidity=0.8.1;

contract Trust {
    //address public kid;
    //uint public maturity;
    struct Kid {
        uint amount;
        uint maturity;
        bool paid;
    }

    mapping(address => Kid) public kids;
    // mapping(address => uint) public amounts;
    // mapping(address => uint) public maturities;
    // mapping(address => bool) public paid;
    address public admin;

    //0x22352as32w5 => 0x345wg34sef3
    //time is in epoch time

    constructor() {
        admin = msg.sender;
    }

    function addKid(address kid, uint timeToMaturity) external payable {
        require(msg.sender == admin, 'only parent can send eth');
        require(kids[msg.sender].amount > 0, 'kid already exists');
        kids[kid] = Kid(msg.sender, block.timestamp + timeToMaturity, false);
        // amounts[kid] = msg.value;
        // maturities[kid] = block.timestap + ttomeToMaturity;
    }
    //constructor(address _kid, uint timeToMaturity) payable {
    //    maturity = block.timestamp + timeToMaturity;
    //    kid = _kid;
    //}

    function withdraw() external {
        Kid storage kid = kids[msg.sender];
        require(kid.maturity <= block.timestamp, 'too early');
        require(kid.amount > 0, 'only kid can withdraw');
        require(kid.paid == false. 'paid already');
        kid.paid = true;
        payable(msg.sender).transfer(kid.amount);
    }

    // function withdraw() external {
    //     require(block.timestamp >= maturity, 'too early to withdraw');
    //     require(msg.sender == kid, 'only child can withdraw eth');
    //     payable(msg.sender).transfer(address(this).balance);
    //     address, address payable;
    // }
}