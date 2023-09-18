pragma solidity ^0.4.19;

import "./ERC223ReceivingContract1.sol";

/// @title Base Token contract - Functions to be implemented by token contracts.
contract EwaToken {
    /*
     * Implements ERC 20 standard.
     * https://github.com/ethereum/EIPs/issues/20
     *
     *  Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     *  https://github.com/ethereum/EIPs/issues/223
     */

    /*
     * This is a slight change to the ERC20 base standard.
     * function totalSupply() constant returns (uint256 supply);
     * is replaced with:
     * uint256 public totalSupply;
     * This automatically creates a getter function for the totalSupply.
     * This is moved to the base contract since public getter functions are not
     * currently recognised as an implementation of the matching abstract
     * function by the compiler.
     */
    uint256 public totalSupply;

    /*
     * ERC 20
     */
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    /*
     * ERC 223
     */
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

    /*
     * Events
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // There is no ERC223 compatible Transfer event, with `_data` included.
}


/// @title Standard token contract - Standard token implementation.
contract StandardToken is EwaToken {

    /*
     * Data structures
     */
    mapping (address => uint256) balanceOf;
    mapping (address => mapping (address => uint256)) allowed;

    /*
     * Public functions
     */
    /// @notice Send `_value` tokens to `_to` from `msg.sender`.
    /// @dev Transfers sender's tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice Send `_value` tokens to `_to` from `msg.sender` and trigger
    /// tokenFallback if sender is a contract.
    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @param _data Data to be sent to tokenFallback
    /// @return Returns success of function call.
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

    /// @notice Transfer `_value` tokens from `_from` to `_to` if `msg.sender` is allowed.
    /// @dev Allows for an approved third party to transfer tokens from one
    /// address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balanceOf[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Allows `_spender` to transfer `_value` tokens from `msg.sender` to any address.
    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read functions
     */
    /// @dev Returns number of allowed tokens that a spender can transfer on
    /// behalf of a token owner.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        view
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by the given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
     balanceOf(address _owner) view public returns (uint256) {
        return balanceOf[_owner];
    }
}


/// @title EwaToken
contract Token is EwaToken {

    /*
     *  Terminology:
     *  1 token unit = Rei
     *  1 token = EWA = Rei * multiplier
     *  multiplier set from token's number of decimals (i.e. 10 ** decimals)
     */

    /*
     *  Token metadata
     */
    string constant public name = "EwaToken";
    string constant public symbol = "EWA";
    uint8 constant public decimals = 18;
    uint constant multiplier = 10 ** uint(decimals);

    event Deployed(uint indexed _total_supply);
    event Burnt(
        address indexed _receiver,
        uint indexed _num,
        uint indexed _total_supply
    );

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets dutch auction contract address
    /// and assigns all tokens to dutch auction.
    /// @param auction_address Address of dutch auction contract.
    /// @param wallet_address Address of wallet.
    /// @param initial_supply Number of initially provided token units (Rei).
    function Token(
        address auction_address,
        address wallet_address,
        uint initial_supply)
        public
    {
        // Auction address should not be null.
        require(auction_address != 0x0);
        require(wallet_address != 0x0);

        // Initial supply is in Rei
        require(initial_supply > multiplier);

        // Total supply of Rei at deployment
        totalSupply = initial_supply;

        balanceOf[auction_address] = initial_supply / 2;
        balanceOf[wallet_address] = initial_supply / 2;

        emit Transfer(0x0, auction_address, balanceOf[auction_address]);
        emit Transfer(0x0, wallet_address, balanceOf[wallet_address]);

        emit Deployed(totalSupply);

        assert(totalSupply == balanceOf[auction_address] + balanceOf[wallet_address]);
    }

    /// @notice Allows `msg.sender` to simply destroy `num` token units (Rei). This means the total
    /// token supply will decrease.
    /// @dev Allows to destroy token units (Rei).
    /// @param num Number of token units (Rei) to burn.
    function burn(uint num) public {
        require(num > 0);
        require(balanceOf[msg.sender] >= num);
        require(totalSupply >= num);

        uint pre_balance = balanceOf[msg.sender];

        balanceOf[msg.sender] -= num;
        totalSupply -= num;
        emit Burnt(msg.sender, num, totalSupply);
        emit Transfer(msg.sender, 0x0, num);

        assert(balanceOf[msg.sender] == pre_balance - num);
    }

}
