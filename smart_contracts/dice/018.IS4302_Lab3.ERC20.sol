pragma solidity ^0.5.0;

// first need to approve the address of spender 
// Check the allowance
// Finally able to call transferFrom to transfer tokens
// tx.origin is a security vulnerability, should avoid using

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
    using SafeMath for uint256;
    
    bool public mintingFinished = false;
    
    // owner is the DiceToken contract that imports and calls ERC20 contract ???
    address public owner = msg.sender;
    
    // table of owner account address => (allowed account address => allowed amount)
    // used in transferFrom(), approve(), allowance()
    mapping (address => mapping (address => uint256)) internal allowed;


    // used in balanceOf(), transfer(), transferFrom(), mint()
    mapping(address => uint256) balances;
    
    
    string public constant name = "DiceToken";
    string public constant symbol = "DT";
    uint8 public constant decimals = 18;
    uint256 totalSupply_;
  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

  



  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[tx.origin], "msg.sender doesn't have enough balance");

    balances[tx.origin] = balances[tx.origin].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(tx.origin, _to, _value);
    return true;
  }



  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from], "From doesn't have enough balance");
    require(_value <= allowed[_from][tx.origin], "Not allowed to spend this much");


    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][tx.origin] = allowed[_from][tx.origin].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function diceTokenTransferFrom(address _from, address _spender, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from], "From doesn't have enough balance");
    // require(_value <= allowed[_from][tx.origin], "Not allowed to spend this much");
    // original transferFrom uses tx.origin which does not work here
    // here changed to explicitly pass the spender address in arg
    // TODO verify: tx.origin here is not the spender, it might be the user account, which maps _from to _from which is incorrect
    require(_value <= allowed[_from][_spender], "Not allowed to spend this much");


    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    // allowed[_from][tx.origin] = allowed[_from][tx.origin].sub(_value);
    // original transferFrom uses tx.origin which does not work here 
    // here changed to explicitly pass the spender address in arg
    // TODO verify: tx.origin here is not the spender, it might be the user account, which maps _from to _from which is incorrect
    allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    // if change msg.sender to tx.origin
    // allowed[tx.origin][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    // emit Approval(tx.origin, _spender, _value);
    return true;
  }

  function diceTokenApprove(address _owner, address _spender, uint256 _value) public returns (bool) {
    allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  
    /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
  function getOwner() public view returns (address){
      return owner;
  }
  
  
   modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }



    
}