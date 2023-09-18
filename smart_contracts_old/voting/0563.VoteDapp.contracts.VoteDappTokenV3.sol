pragma solidity ^0.7.0;

//WARNING: APPROVE FUNCTION DOES NOT CHECK IF OWNER HAS THE CORRECT AMOUNT OF VDA TOKENS

import "./SafeMath.sol";

contract VoteDappToken {
    
    using SafeMath for uint256;
    
    string  public name = "VoteDapp Token";
    string  public symbol = "VDA";
    string  public standard = "ERC20";
    uint256 public totalSupply;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    event Sell(address _buyer, uint256 _amount);
    
    event Return(address _buyer, uint256 _amount);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //does not work in ganache
    constructor (uint256 _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    
    }
    
    //for poeple who want to transfer their own coins
    function transfer(address _to, uint256 _value) external returns (bool) {
        
        require(balanceOf[msg.sender] >= _value, "You don't have enough tokens.");
        
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
    //WARNING: APPROVE FUNCTION DOES NOT CHECK IF OWNER HAS THE CORRECT AMOUNT OF VOTT TOKENS
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value; //allows a contract or person to spend on behalf of an address

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    //for people who are not the owners of the coins.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from], "Not enough tokens."); //checks if source has enough money
        require(_value <= allowance[_from][msg.sender], "Did not approve amount."); //checks if spender is allowed to spend this amount

        balanceOf[_from] = balanceOf[_from].sub(_value); //takes money away from source
        balanceOf[_to] = balanceOf[_to].add(_value); //gives money to address

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); //takes away the allowance from the spender

        emit Transfer(_from, _to, _value);

        return true;
    }
}
