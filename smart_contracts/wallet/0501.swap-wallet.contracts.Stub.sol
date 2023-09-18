pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stub is ERC20 {

    constructor() ERC20("Green Token", "Grn") {
        _mint(msg.sender, 100000 * (10 ** decimals())); //mint tokens: supply amt of tokens with decimal
    }

    //keeps record of the balance of each of a wallet address' ERC20 Token
    mapping (address => mapping(address => uint)) tokenBalance;

    //deposit funds in the smart contract
    function deposit(address _token, uint _amount) private {
        tokenBalance[msg.sender][_token] = tokenBalance[msg.sender][_token] + _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    //withdraw funds from smart contract
    function withdraw(address _token, uint _amount) private {
        require(tokenBalance[msg.sender][_token] >= _amount, "Lack of funds");
        tokenBalance[msg.sender][_token] = tokenBalance[msg.sender][_token] - _amount;
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }

        // allows payments with the smart contract
    function payWithWallet(address _token, uint _price, address _addressPaidTo) public {
        require(tokenBalance[msg.sender][_token] >= _price, "Lack of funds");
        tokenBalance[msg.sender][_token] = tokenBalance[msg.sender][_token] - _price;
        IERC20(_token).transferFrom(address(this), _addressPaidTo, _price);
    }

    //modifier for trading tokens between wallet addresses (assures enough funds are stored in the wallet addresses)
    modifier enoughTokens(address _inputToken, address _with, address _outputToken, uint _amount) {
        require(tokenBalance[msg.sender][_inputToken] >= _amount, "Lack of funds");
        require(tokenBalance[_with][_outputToken] >= _amount, "Lack of funds");
        _;
    }

    //swap tokens
    function swap(
        address _inputToken,
        address _with,
        address _outputToken,
        uint _requestedAmount
    ) external enoughTokens(_inputToken, _with, _outputToken, _requestedAmount) {
        tokenBalance[msg.sender][_inputToken] = tokenBalance[msg.sender][_inputToken] - _requestedAmount;
        tokenBalance[msg.sender][_outputToken] = tokenBalance[msg.sender][_outputToken] + _requestedAmount;
        tokenBalance[_with][_inputToken] = tokenBalance[_with][_inputToken] + _requestedAmount;
        tokenBalance[_with][_outputToken] = tokenBalance[_with][_outputToken] - _requestedAmount;
    }

}
