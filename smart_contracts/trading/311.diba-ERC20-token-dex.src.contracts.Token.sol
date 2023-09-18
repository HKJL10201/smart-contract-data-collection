pragma solidity >=0.4.22 <0.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
    using SafeMath for uint;

    // Variables
    string public name = "DiBa Token";
    string public symbol = "DiBa";
    uint256 public decimals = 18;
    uint256 public totalSupply;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Track balances
    mapping(address => uint256) public balanceOf;

    // Tracks allowance - How many tokens the exchange is allowed to expend
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        totalSupply = 1000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    // Send tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    // Aprove tokens
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Transfer from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       // _value must be equal or the less of the balance of the _from account - spender
       // must have the tokens to complete the transfer
       require(_value <= balanceOf[_from]);
       // _value must be equal or the less of the approved amount for the exchange itself
       require(_value <= allowance[_from][msg.sender]);
       allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
}

