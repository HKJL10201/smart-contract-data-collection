// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

contract Tether {
    string public _name = 'Mock Tether Token';                                           // Name of the Token
    string public _symbol = 'mUSDT';                                                     // Symbol of the token
    uint256 _totalSupply = 1000000000000000000000000;                                    // Total supply of the token in Wei
    uint8 _decimals = 18;                                                                // Decimal digits for Wei

    mapping(address => uint256) public _accountBalance;                                  // Store information of user account holder's balance
    mapping(address => mapping(address => uint256)) public _allowance;                   // Store information of allowance approval e.g (person X approves to let person Y take Z amount of tokens)

    // Event log for transferring tokens
    event Transfer(
        address indexed _transferFrom, 
        address indexed _transferTo, 
        uint256 _transferAmount
    );

    // Event logs for approval token for transfer
    event Approval(                                                                                                                                        
        address indexed _approvalFrom,
        address indexed _approvalTo, 
        uint256 _approvalAmount
    ); 

    // Initialize an instance of the Tether contract
    constructor() {
        _accountBalance[msg.sender] = _totalSupply;                                      // Gives total supply of token to owner as the contract is initiated
    }

    // Function for approval of token transfer
    function _approval(address _approvalTo, uint256 _approvalAmount) public returns (bool success) {

       
        require(                                                                          // The token amount in user's account must be greater or equal to approved token amount to initial approval 
            _approvalAmount <=  _accountBalance[msg.sender],
            'Insufficient token in account!'
        );
        
        _allowance[msg.sender][_approvalTo] = _approvalAmount;                           // Assigns the approved token amount to respected approved user account holders
        emit Approval(msg.sender, _approvalTo, _approvalAmount);                         // Emit the event log and assign respected values to the variables

        return true;
    }

    // Function for standard transfer of tokens
    function _transfer(address _transferTo, uint256 _transferAmount) public returns (bool success) {

        
        require(                                                                         // The token amount in user's account must be greater than or equal to the token amount entered for transfer
            _accountBalance[msg.sender] >= _transferAmount,
            'Insufficient token in account!!'
        );

        _accountBalance[_transferTo] += _transferAmount;                                 // Transfer the amount of token to the reciever's account
        _accountBalance[msg.sender] -= _transferAmount;                                  // Substracts the amount of token entered for transfer from the user's account 
        emit Transfer(msg.sender, _transferTo, _transferAmount);                         // Emit the event log and assign respected values to the variables

        return true;
    }

    // Function for third party transfer
    function _thirdPartyTransfer(address _transferFrom, address _transferTo, uint256 _transferAmount) public returns (bool success) {

        require(                                                                         // The token amount in user's account must be greater than or equal to the token amount entered for transfer
            _accountBalance[_transferFrom] >= _transferAmount,
            'Insufficient token in account!!!'
        );

        
        require(                                                                         // The token amount in the approved allowance account must be greater than or equal to the token amount entered for transfer
            _allowance[_transferFrom][_transferTo] >= _transferAmount,
            'Amount entered does not match with Approval allowance account token'
        );
        
        _accountBalance[_transferTo] += _transferAmount;                                 // Transfer the token amount to the reciever's account
        _accountBalance[_transferFrom] -= _transferAmount;                               // Substracts the token amount of the user's account by the token amount entered
        _allowance[_transferFrom][_transferTo] -= _transferAmount;                       // Substracts the token amount of the approved allowance account by the token amount entered
        
        emit Transfer(_transferFrom, _transferTo, _transferAmount);                      // Emit the event log and assign respected values to the variables
        
        return false;
    }


}