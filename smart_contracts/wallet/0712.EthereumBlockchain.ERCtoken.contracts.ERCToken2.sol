pragma solidity ^0.4.11;

contract ERCToken {
    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    uint256 public lotteryPot;
    uint256 private winningNumber;
    address creator;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Constructor
    function ERCToken (uint _totalSupply) {
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        
        // the creator of the contract controls the lottery
        creator = msg.sender;
    }

    function name() constant returns (string name) {
        return "ShitCoin";
    }

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender's tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (allowed[_from][msg.sender] >= _value) {
            if (balances[_from] >= _value) {
                balances[_from] -= _value;
                balances[_to] += _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            }
        }
        return false;
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /*
    // Input is a guess of the winningNumber at the cost of 1 coin per entry
    function enterLottery(uint256 _number) returns (bool success) {
        // if lotteryPot == 0 someone knows the winningNumber, so the lottery
        // must be reset by the creator before more entries are allowed
        if (lotteryPot == 0) {
            return false;
        }
    
        if (balances[msg.sender] >= 1) {
            // if the guess was right, msg.sender gets all the money in the pot
            // and the lotteryPot is set to 0
            if (winningNumber == _number) {
                balances[msg.sender] += lotteryPot;
                lotteryPot = 0;
                return true;
            // if the guess is wrong, msg.sender puts one coin into the pot
            } else {
                balances[msg.sender] -= 1;
                lotteryPot += 1;
                return true;
            }
        }
        return false;
    }
    
    // Allows creator to reset amount in lotteryPot and the winningNumber
    function resetLottery(uint256 _amount, uint256 _winningNumber) returns (bool success) {
        if (msg.sender == creator) {
            if (balances[creator] >= _amount) {
                balances[creator] += lotteryPot;
                lotteryPot == _amount;
                winningNumber = _winningNumber;
                return true;
            }
        }
        return false;
    }
    */

}
