pragma solidity ^0.8.11;

import "./PoiToken.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Exchange is Initializable{
	address public feeAccount; //account to receive exchange fees
	uint256 public feePercent; // fee percentage
	address constant ETHER = address(0); // Placeholder ether address
	uint256 public orderCount;

	mapping(address => mapping(address => uint256)) public tokens;
	mapping(uint256 => _Order) public orders;
	mapping(uint256 => bool) public orderCancelled;
	mapping(uint256 => bool) public orderFilled;

	event Deposit(address token, address user, uint256 amount, uint256 balance);
	event Withdraw(address token, address user, uint256 amount, uint256 balance);
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
		address userFill,
		uint256 timestamp
	);

	struct _Order{
		uint256 id;
		address user;
		address tokenGet;
		uint256 amountGet;
		address tokenGive;
		uint256 amountGive;
		uint256 timestamp;
	}

	// constructor(address _feeAccount, uint256 _feePercent) {
	// 	feeAccount = _feeAccount;
	// 	feePercent = _feePercent;
	// }

	function initialize(address _feeAccount, uint256 _feePercent) public initializer {
        feeAccount = _feeAccount;
		feePercent = _feePercent;
    }

	// Fallback function to revert ether sent to this smart contract by mistake
	fallback() external{
		revert();
	}
	function depositEther() public payable{
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender] + msg.value;
		emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
	}

	function withdrawEther(uint256 _amount) public{
		require(tokens[ETHER][msg.sender] >= _amount);
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender] - _amount;
		payable(msg.sender).transfer(_amount);
		emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
	}

	function depositToken(address _token, uint256 _amount) public {
		require(_token != ETHER);
		require(PoiToken(_token).transferFrom(msg.sender, address(this), _amount));
		tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;

		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function withdrawToken(address _token, uint256 _amount) public {
		require(_token != ETHER);
		require(tokens[_token][msg.sender] >= _amount);

		tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;
		require(PoiToken(_token).transfer(msg.sender, _amount));
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function balanceOf (address _token, address _user) public view returns (uint256){
		return tokens[_token][_user];
	}

	function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
		orderCount++;
		orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, block.timestamp);
		emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, block.timestamp);
	}

	function cancelOrder(uint256 _id) public {
		_Order storage _order = orders[_id];
		require(msg.sender == address(_order.user));
		require(_order.id == _id);

		orderCancelled[_id] = true;
		emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, block.timestamp);
	}

	function fillOrder(uint256 _id) public {
		require(_id > 0 && _id <= orderCount);
		require(!orderFilled[_id]);
		require(!orderCancelled[_id]);

		_Order storage _order = orders[_id];
		_trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
		orderFilled[_order.id] = true;
	}

	// Function lets msg.sender fill user1's order 
	function _trade(uint256 _orderId, address _user, address _tokenGet,
	 uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {

	 	// Fee is paid by the user that fills the order. A.k.a msg.sender
	 	uint256 _feeAmount = (_amountGet * feePercent) / 100; 

		tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender] - (_amountGet + _feeAmount);
		tokens[_tokenGet][_user] = tokens[_tokenGet][_user] + _amountGet;
		tokens[_tokenGive][_user] = tokens[_tokenGive][_user] - _amountGive;
		tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender] + _amountGive;

		// Fee is collected by feeAccount
		tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount] + _feeAmount;

		emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, block.timestamp);
	}

}