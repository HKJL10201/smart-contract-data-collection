pragma solidity ^0.4.24;

// Standard ERC20 contract with Burning && minting capabilities..
// https://theethereum.wiki/w/index.php/ERC20_Token_Standard

import "../Libraries/SafeMath.sol";
import "./ERC20Interface.sol";


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}


/**
 * @title ERC20ERC20BurnableAndMintable
 * @author Connor Howe - ConnorBlockchain
 * @dev Standard ERC20 token contract, with non-fixed supply with burnable and mintable capabilities
 */
contract ERC20BurnableAndMintable is ERC20Interface {
    using SafeMath for uint256;

    /* ---- Events ---- */
    event LogBurn(address indexed _burner, uint indexed _amountBurned);

    /* ---- Storage ---- */
    uint internal supply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    address public owner;

    /**
     * @dev Assigns token values, and assign total supply to owner.
     * @param _initialAmount Total supply, assign to owner of contract.
     * @param _tokenName Name of token.
     * @param _decimalUnits Decimal amount of token.
     * @param _tokenSymbol Symbol of token.
     */
    constructor(uint _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        supply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;                                  // Owner of contract
        emit Transfer(address(0), msg.sender, _initialAmount);    // Transfer event indicating token creation
    }

  /**
   * @dev Transfers tokens from msg.sender, to the _to address for the _amount parameter.
   * @param _to Address to transfer the tokens too.
   * @param _amount Amount of tokens to transfer.
   */
    function transfer(address _to, uint _amount)
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

   /**
    * @dev Transfer tokens from address _from if _from has allowed msg.sender to transfer to _to address, for _amount.
    * @param _from Address to remove _amount from if msg.sender has been approved.
    * @param _to Address to transfer _amount of tokens to.
    * @param _amount Amount of tokens to transfer.
    */
    function transferFrom(address _from, address _to, uint _amount)
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_amount > 0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

   /**
    * @dev Msg.sender can approve another address to transferFrom(...) tokens from msg.senders address.
    * @param _spender Approved address that can transferFrom(...) tokens.
    * @param _amount Amount that _spender can use.
    */
    function approve(address _spender, uint _amount)
        public
        returns (bool success)
    {
        require(_amount > 0);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

   /**
    * @dev Msg.sender can ping a contract that the contract has been approved to spend tokens on msg.senders behalf.
    * @param _spender Contract address that can spend tokens.
    * @param _amount Amount of tokens that the contract can spend.
    * @param _data Arbitrary bytes value passed to contract.
    */
    function approveAndCall(address _spender, uint _amount, bytes _data)
        public
        returns (bool success)
    {
        require(_amount > 0);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);
        emit Approval(msg.sender, _spender, _amount);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _data);
        return true;
    }

   /**
    * @dev Burns _amount of tokens from total supply and msg.senders balance.
    * @param _amount Amount of tokens.
    */
    function burn(uint _amount)
        public
        returns (bool success)
    {
        require(_amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        supply = supply.sub(_amount);
        emit LogBurn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

   /**
    * @dev Burns _amount of tokens from total supply and _from balance if msg.sender has been approved.
    * @param _from Address that tokens will be burnt from if msg.sender has been approved.
    * @param _amount Amount of tokens that will be burnt _from address.
    */
    function burnFrom(address _from, uint _amount)
        public
        returns (bool success)
    {
        require(_amount > 0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        supply = supply.sub(_amount);
        emit LogBurn(_from, _amount);
        emit Transfer(_from, address(0), _amount);
        return true;
    }

   /**
    * @dev Owner introduces new tokens into supply and increases the balance of the _to address.
    * @param _to Address that new tokens will be transferred too.
    * @param _amount Amount of tokens that will be introduced into supply and transfered _to.
    */
    function mint(address _to, uint _amount)
        public
        returns (bool success)
    {
        require(_amount > 0);
        require(msg.sender == owner);
        supply = supply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

   /**
    * @return The amount of tokens released.
    */
    function totalSupply() public view returns (uint tokenSupply) {
        return supply;
    }

    /**
     * @return Token balance of token holder address.
     */
    function balanceOf(address _tokenHolder) public view returns (uint balance) {
        return balances[_tokenHolder];
    }

    /**
     * @return The amount of tokens allowed to be spent by _spender from _tokenHolder.
     */
    function allowance(address _tokenHolder, address _spender) public view returns (uint remaining) {
        return allowed[_tokenHolder][_spender];
    }
}
