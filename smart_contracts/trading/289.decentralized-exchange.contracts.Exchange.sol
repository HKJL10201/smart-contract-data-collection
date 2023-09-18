// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract Exchange {
    address public feeAccount;
    uint256 public feePercent;

    mapping(address => mapping(address => uint256)) public tokens;

    mapping(uint256 => _Order) public orders;
    uint256 public orderCount;

    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address creator,
        uint256 timestamp
    );

    struct _Order {
        //Order Attributes
        uint256 id; //Identifier
        address user; //User that ordered
        address tokenGet; //Address of token to get
        uint256 amountGet; //Amount of token to get
        address tokenGive; //Address of token to give
        uint256 amountGive; //Amount of token to give
        uint256 timestamp; //When order was created
    }

    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    //--------------------------
    //DEPOSIT AND WITHDRAW TOKEN
    //--------------------------

    function depositToken(address _token, uint256 _amount) public {
        //Transfer Tokens to Exchange
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        //Update balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;
        //Emit an Event
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(tokens[_token][msg.sender] >= _amount);
        Token(_token).transfer(msg.sender, _amount);
        tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return tokens[_token][_user];
    }

    //--------------------------
    //MAKE AND CANCEL ORDERS
    //--------------------------

    function makeOrder(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) public {
        //Require token balance
        require(balanceOf(_tokenGive, msg.sender) >= _amountGive);
        //Create order with order structure
        orderCount++;
        orders[orderCount] = _Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
        //Emit Event
        emit Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
    }

    function cancelOrder(uint256 _id) public {
        //Fetching the order
        _Order storage _order = orders[_id];
        //Ensure the caller of the function id the owner of the order
        require(address(_order.user) == msg.sender);
        //Order must exist
        require(_order.id == _id);
        //Cancel the order
        orderCancelled[_id] = true;
        //Emit Event
        emit Cancel(
            _order.id,
            msg.sender,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive,
            block.timestamp
        );
    }

    //--------------------------
    //MAKE AND CANCEL ORDERS
    //--------------------------

    function fillOrder(uint256 _id) public {
        //Must be valid orderId
        require(_id > 0 && _id <= orderCount, "Order does not exist");
        //Order can't be filled
        require(!orderFilled[_id]);
        //Order can't be canceled\
        require(!orderCancelled[_id]);

        //Fetch Order
        _Order storage _order = orders[_id];
        //Execute Trade
        _trade(
            _order.id,
            _order.user,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive
        );

        orderFilled[_order.id] = true;
    }

    function _trade(
        uint256 _orderId,
        address _user,
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) internal {
        uint256 _feeAmount = (_amountGet * feePercent) / 100;
        //User2 pays tokenGet and Fee (in tokenGet)
        tokens[_tokenGet][msg.sender] =
            tokens[_tokenGet][msg.sender] -
            (_amountGet + _feeAmount);
        //User1 gets paid tokenGet
        tokens[_tokenGet][_user] = tokens[_tokenGet][_user] + _amountGet;
        //Fee Account gets paid feeAmount in tokenGet
        tokens[_tokenGet][feeAccount] =
            tokens[_tokenGet][feeAccount] +
            _feeAmount;
        //User1 pays tokenGive
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user] - _amountGive;
        //User2 gets paid tokenGive
        tokens[_tokenGive][msg.sender] =
            tokens[_tokenGive][msg.sender] +
            _amountGive;

        //Emit Event
        emit Trade(
            _orderId,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            _user,
            block.timestamp
        );
    }
}
