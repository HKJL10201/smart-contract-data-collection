pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Wallet {
    address public autoSaveAccount;
    uint256 public autoSavePercent;
    uint256 public depositCount;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public tokens;

    constructor(address _autoSaveAccount) public {
        autoSaveAccount = _autoSaveAccount;
    }

    event Deposit(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    fallback() external payable {
        revert();
    }

    function depositToken() public payable {
        require(Token(_token).transferFrom(msg.sender, address(this), amount), 'call of transferFrom does not match');
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount, token[_token][msg.sender]);   
    }

    function _autoSave(
        address _user,
        address _tokenGive,
        uint256 _amountGive,
        internal {
            uint256 _autoSaveAmount = _amountGive.mul(autoSavePercent).div(100);
            tokens[_tokenGive][msg.sender] = tokens [_tokenGive][msg.sender].add(amountGive);
            emit autoSave(_depositId, _user, _tokenGive, _amountGive, msg.sender, now;)
        }

    )

    function withdrawToken(uint256 _amount) public payable {
        require(token[_token][msg.sender] >= _amount, 'Insufficient funds');
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        required(Token(_token).transfer(msg.sender, _amount) 'call of transfer does not match');
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns(uint256) {
        return tokens[_token][_user];
    }


}


//Add SafeMath

