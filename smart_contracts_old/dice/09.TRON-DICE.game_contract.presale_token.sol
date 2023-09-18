pragma solidity ^0.4.25;

interface ITRC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


contract Presale is Ownable {
    using SafeMath for uint;

    bool _start = false;
    address public _tokenAddr;
    address public _tokenHolder;
    uint public _amount;
    uint public _price = 10;
    uint public _minAmount = 1000000;

    uint public SaleAmount = 0;
    uint public SaleIncome = 0;
    uint public RemainingAmount = 0;


    struct Record {
        uint amount;
        uint cost;
        uint cnt;
    }

    mapping(address => Record) private _record;

    event onStartPresale(address tokenAddr, address holder, uint amount);
    event onPriceChange(uint oldPrice, uint newPrice);
    event onSale(address userAddr, uint cost, uint amount);

    constructor () public {
    }

    modifier onlyStart {
        require(_start = true);
        _;
    }

    function() external payable {
        revert();
    }
    
    function adminWithdraw(address addr) public onlyOwner {
        require(address(0) != addr && address(this).balance > 0);
        addr.transfer(address(this).balance);
    }

    function setPresaleTokenInfo(address token, address holder, uint amount) public onlyOwner {
        require(address(0) != token && address(0) != holder && amount > 1000000);
        _tokenAddr = token;
        _tokenHolder = holder;
        _amount = amount;
        RemainingAmount = amount;
        require(ITRC20(_tokenAddr).allowance(_tokenHolder, address(this)) >= _amount);
        emit onStartPresale(token, holder, amount);
        _start = true;
    }

    function setMinBuyAmount(uint amount) public onlyOwner {
        require(amount >= 1000000);
        _minAmount = amount;
    }
    
    function setPrice(uint price) public onlyOwner {
        require(price >= 0);
        emit onPriceChange(_price, price);
        _price = price;
    }

    function buy() public payable onlyStart {
        require(msg.value >= _minAmount * _price);
        uint amount = msg.value / _price;
        require(amount > 0);
        if (!ITRC20(_tokenAddr).transferFrom(_tokenHolder, msg.sender, amount)) {
            revert();
        }
        _tokenHolder.transfer(msg.value);
        _record[msg.sender].amount += amount;
        _record[msg.sender].cost += msg.value;
        _record[msg.sender].cnt += 1;
        SaleAmount += amount;
        SaleIncome += msg.value;
        RemainingAmount -= amount;
        emit onSale(msg.sender, msg.value, amount);
    }

    function record(address addr) public view returns(uint, uint, uint) {
        return (_record[addr].amount, _record[addr].cost, _record[addr].cnt);
    }
}
