pragma solidity ^0.5.2;


import "./ERC20.sol";


// ----------------------------------------------------------------------------
// Bookeeper contract that holds the amount of dividents in Ether.
// ----------------------------------------------------------------------------
contract Dividend is ERC20 {

    uint8 public constant dividendsCosts = 10; // Dividends 10%.
    uint16 public constant day = 6000;
    uint256 public dividendes; // storage for Dividends.

    mapping(address => uint256) bookKeeper;


    event SendOnDividend(address indexed customerAddress, uint256 dividendesAmount);
    event WithdrawDividendes(address indexed customerAddress, uint256 dividendesAmount);

    constructor() public {}


    // ------------------------------------------------------------------------
    // Withdraw dividendes.
    // ------------------------------------------------------------------------
    function withdrawDividendes() external payable returns(bool success) {
        require(msg.sender.isNotContract(),
                "the contract can not hold tokens");

        uint256 _tokensOwner = balanceOf(msg.sender);

        require(_tokensOwner > 0, "cannot pass 0 value");
        require(bookKeeper[msg.sender] > 0,
                "to withdraw dividends, please wait");

        uint256 _dividendesAmount = dividendesCalc(_tokensOwner);

        require(_dividendesAmount > 0, "dividendes amount > 0");

        bookKeeper[msg.sender] = block.number;
        dividendes = dividendes.sub(_dividendesAmount);

        msg.sender.transfer(_dividendesAmount);

        emit WithdrawDividendes(msg.sender, _dividendesAmount);

        return true;
    }


    // ------------------------------------------------------------------------
    // Get value of dividendes.
    // ------------------------------------------------------------------------
    function dividendesOf(address _owner)
        public
        view
        returns(uint256 dividendesAmount) {
        uint256 _tokens = balanceOf(_owner);

        dividendesAmount = dividendesCalc(_tokens);
    }


    // ------------------------------------------------------------------------
    // Count percent of dividendes from ether.
    // ------------------------------------------------------------------------
    function onDividendes(uint256 _value, uint8 _dividendsCosts)
        internal
        pure
        returns(uint256 forDividendes) {
        return _value.mul(_dividendsCosts).div(100);
    }


    // ------------------------------------------------------------------------
    // Get number of dividendes in ether
    // * @param _tokens: Amount customer tokens.
    // * @param _dividendesPercent: Customer tokens percent in 10e18.
    // *
    // * @retunrs dividendesReceived: amount of dividendes in ether.
    // ------------------------------------------------------------------------
    function dividendesCalc(uint256 _tokensAmount)
        internal
        view
        returns(uint256 dividendesReceived) {
        if (_tokensAmount == 0) {
            return 0;
        }

        uint256 _tokens = _tokensAmount.mul(10e18);
        uint256 _dividendesPercent = dividendesPercent(_tokens); // Get % from tokensOwner.

        dividendesReceived = dividendes.mul(_dividendesPercent).div(100);
        dividendesReceived = dividendesReceived.div(10e18);
    }


    // ------------------------------------------------------------------------
    // Get number of dividendes in percent
    // * @param _tokens: Amount of (tokens * 10e18).
    // * returns: tokens % in 10e18.
    // ------------------------------------------------------------------------
    function dividendesPercent(uint256 _tokens)
        internal
        view
        returns(uint256 percent) {
        if (_tokens == 0) {
            return 0;
        }

        uint256 _interest = accumulatedInterest();

        if (_interest > 100) {
            _interest = 100;
        }

        percent = _tokens.mul(_interest).div(totalSupply);
    }


    // ------------------------------------------------------------------------
    // Block value when buying.
    // ------------------------------------------------------------------------
    function accumulatedInterest() private view returns(uint256 interest) {
        if (bookKeeper[msg.sender] == 0) {
            interest = 0;
        } else {
            interest = block.number.sub(bookKeeper[msg.sender]).div(day);
        }
    }

}
