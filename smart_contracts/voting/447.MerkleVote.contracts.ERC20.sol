pragma solidity >=0.5.0 <0.6.0;


interface ApproveAndCallFallBack { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

import './SafeMath.sol';
// ------------------------------------------------------------------------
// Standard ERC20 Token Contract.
// Fixed Supply with burn capabilities
// ------------------------------------------------------------------------
contract ERC20 {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    /// Token supply, balances and allowance
    // ------------------------------------------------------------------------
    uint internal supply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    // ------------------------------------------------------------------------
    // Token Information
    // ------------------------------------------------------------------------
    string public name;                   // Full Token name
    uint8 public decimals;                // How many decimals to show
    string public symbol;                 // An identifier


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol)
    public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        supply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        emit Transfer(address(0), msg.sender, _initialAmount);    // Transfer event indicating token creation
    }


    // ------------------------------------------------------------------------
    // Transfer _amount tokens to address _to
    // Sender must have enough tokens. Cannot send to 0x0.
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount)
    public
    returns (bool success) {
        require(_to != address(0));         // Use burn() function instead
        require(_to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // // ------------------------------------------------------------------------
    // // Transfer _amount of tokens if _from has allowed msg.sender to do so
    // //  _from must have enough tokens + must have approved msg.sender
    // // ------------------------------------------------------------------------
    // function transferFrom(address _from, address _to, uint _amount)
    // public
    // returns (bool success) {
    //     require(_to != address(0));
    //     require(_to != address(this));
    //     balances[_from] = balances[_from].sub(_amount);
    //     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    //     balances[_to] = balances[_to].add(_amount);
    //     emit Transfer(_from, _to, _amount);
    //     return true;
    // }
    //
    // // ------------------------------------------------------------------------
    // // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // // from the token owner's account
    // // ------------------------------------------------------------------------
    // function approve(address _spender, uint _amount)
    // public
    // returns (bool success) {
    //     allowed[msg.sender][_spender] = _amount;
    //     emit Approval(msg.sender, _spender, _amount);
    //     return true;
    // }
    //
    //
    // // ------------------------------------------------------------------------
    // // Token holder can notify a contract that it has been approved
    // // to spend _amount of tokens
    // // ------------------------------------------------------------------------
    // function approveAndCall(address _spender, uint _amount, bytes _data)
    // public
    // returns (bool success) {
    //     allowed[msg.sender][_spender] = _amount;
    //     emit Approval(msg.sender, _spender, _amount);
    //     ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _data);
    //     return true;
    // }

    // ------------------------------------------------------------------------
    // Returns the number of tokens in circulation
    // ------------------------------------------------------------------------
    function totalSupply()
    public
    view
    returns (uint tokenSupply) {
        return supply;
    }

    // ------------------------------------------------------------------------
    // Returns the token balance of user
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenHolder)
    public
    view
    returns (uint balance) {
        return balances[_tokenHolder];
    }

    // ------------------------------------------------------------------------
    // Returns amount of tokens _spender is allowed to transfer or burn
    // ------------------------------------------------------------------------
    function allowance(address _tokenHolder, address _spender)
    public
    view
    returns (uint remaining) {
        return allowed[_tokenHolder][_spender];
    }


    // ------------------------------------------------------------------------
    // Fallback function
    // Won't accept ETH
    // ------------------------------------------------------------------------
    function ()
    external
    payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Event: Logs the amount of tokens burned and the address of the burner
    // ------------------------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
