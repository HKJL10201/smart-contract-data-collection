pragma solidity ^0.4.15;

contract SafeMath {
	function safeMul(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeSub(uint256 a, uint256 b) internal returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);
		return c;
	}
}

contract TradingToken is SafeMath {
    /**
     * Represents the name of the contract [Token], used as display name for wallets.
     */
    string public name = "Trading Token";

    /**
     * Represents the symbol of the contract [Token], used as display symbol for wallets.
     */
    string public symbol = "TTK";

    /**
     * Represents the decimal positions of the contract [Token], used as display symbol for wallets.
     */
    uint8 public decimals = 8;

    /**
     * Represents the owner's address of the contract.
     */
    address public ownerAddress;

    /**
     * Represents the address where the ETH funds will be located.
     */
    address public fundsAddress;

    /**
     * Represents the token initial total supply. [TTK 1,000,000,000]
     */
    uint256 public initialTotalSupply;

    /**
     * Represents the token current total supply.
     */
    uint256 public currentTotalSupply;

    /**
     * Represents the tokens amount that will be reserved. [TTK 300,000,000]
     */
    uint256 public reservedTokensAmount = getTokenAmount(300000000);

    /**
     * Represents the tokens amount that will be distributed on the ICO. [TTK 700,000,000]
     */
    uint256 public icoTokensAmount = getTokenAmount(700000000);

    /**
     * Represents the tokens amount that are currently sold on the ICO.
     */
    uint256 public icoSoldTokensAmount = 0;

    /**
     * Represents a boolean value specifying if the non adquired ico tokens has been burnt.
     */
    bool public isBurned = false;

    /**
     * Represents a boolean value specifying if the ico is totally sold and can be tradable.
     */
    bool public isIcoSold = false;

    /**
     * [ERC20 compliant] - Allow identify the address balances, used by clients to display address balances.
     */
    mapping (address => uint256) public balanceOf;

    /**
     * [ERC20 compliant] - Allow identify the address allowances, (An address allow other addresses to spend tokens on his behalf).
     */
    mapping (address => mapping (address => uint256)) public allowance;

    /**
     * Represents the date where the token will be available.
     */
    uint public startDate;

    /**
     * Represents the date where the token will stop to be available and the ones don't distributed will get burn.
     */
    uint public endDate;

    /**
     * [ERC20 compliant] - An event triggered when a fund transfer has occurs, comonly used by clients.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * [ERC20 compliant] - An event triggered when a fund burns has occurs, comonly used by clients.
     */
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor
     *
     * Initializes a contract and gives the initial supply to the token creator.
     */
    function TradingToken(address _fundsAddress, uint _startDate, uint _icoDurationInWeeks) public {
        ownerAddress = msg.sender;
        fundsAddress = _fundsAddress;

        changeIcoStartDate(_startDate, (_icoDurationInWeeks * 1 weeks) / 1 minutes);

        initialTotalSupply = icoTokensAmount + reservedTokensAmount; 
        currentTotalSupply = initialTotalSupply;

        balanceOf[ownerAddress] = currentTotalSupply;
    }

    /**
     * Transfers the provided funds `_value` from the provided `_from` address to the provided `_to` address.
     *
     * @param _from Represents the address where the funds will be subtracted.
     * @param _to Represents the address where the funds will be added.
     * @param _value Represents the funds that will be transfered.
     *
     */
    function internalTransfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(safeAdd(balanceOf[_to], _value) > balanceOf[_to]);

        uint previousBalances = safeAdd(balanceOf[_from], balanceOf[_to]);

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);

        assert(safeAdd(balanceOf[_from], balanceOf[_to]) == previousBalances);
    }

    /**
     * [ERC20 compliant] - Transfers the provided funds `_value` to the provided `_to` address.
     *
     * @param _to Represents the address where the funds will be transfered.
     * @param _value Represents the funds that will be transfered.
     *
     */
    function transfer(address _to, uint256 _value) public {
        require(now > endDate || isIcoSold);

        if (msg.sender == ownerAddress && now <= (endDate + 365 days)) {
            require(safeSub(balanceOf[msg.sender], _value) >= getTokenAmount(150000000));
        }

        internalTransfer(msg.sender, _to, _value);
    }

    /**
     * [ERC20 compliant] - Transfers the provided funds `_value` in behalf of the the provided `_from` address to the provided `_to` address.
     *
     * @param _from Represents the address where the funds will be subtracted.
     * @param _to Represents the address where the funds will be added.
     * @param _value Represents the funds that will be transfered.
     *
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        internalTransfer(_from, _to, _value);
        return true;
    }


    /**
     * [ERC20 compliant] - Approves the provided `_spender` address to spend the provided `_value` on behalf the current address [Sender].
     *
     * @param _spender Represents the address that will be able to spend the provided value.
     * @param _value Represents the value that the spender addres will be able to spend.
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) 
    {
        require(_value >= 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }  


    /**
     * [ERC20 compliant] - Remove permanently the waste token amount.
     */
    function burn() public {
        require(msg.sender == ownerAddress);
        require(balanceOf[msg.sender] > reservedTokensAmount);
        require(now > endDate || isIcoSold);
        require(!isBurned);

        uint256 toBurnAmount = safeSub(balanceOf[msg.sender], reservedTokensAmount);
        balanceOf[msg.sender] = reservedTokensAmount;
        currentTotalSupply = safeSub(currentTotalSupply, toBurnAmount);
        Burn(msg.sender, toBurnAmount);
        isBurned = true;        
    }

    /**
     * Represents the functio that will be executed when the contract receive ethereums and will supply the tokens.
     */
    function () payable {  
        require(now > startDate && now < endDate);              
        require(msg.value >= (0.3 * 1 ether));
        uint256 tokenAmount = getTokenAmountPerETH(msg.value);
        require(tokenAmount <= safeSub(icoTokensAmount, icoSoldTokensAmount));
        require(!isIcoSold);
        require(!isBurned);

        fundsAddress.transfer(msg.value);
        internalTransfer(ownerAddress, msg.sender, tokenAmount);

        icoSoldTokensAmount += tokenAmount;
        isIcoSold = icoSoldTokensAmount >= icoTokensAmount;        
    }

    /**
     * Allow the contract owner change the ICO start date.
     * @param _startDate Represents the new start date for the ICO.
     * @param _durationInMinutes Represents the ICO duration in minutes.
     */
    function changeIcoStartDate(uint _startDate, uint _durationInMinutes) public {
        require(msg.sender == ownerAddress);
        require(!isIcoSold);

        startDate = _startDate;
        endDate = startDate + (_durationInMinutes * 1 minutes);
    }

    /**
     * Returns the token amount based on a given amount;
     */
    function getTokenAmount(uint256 amount) internal 
        returns (uint256 resultAmount) 
    {
        return safeMul(amount, 10 ** uint256(decimals));
    }

    /**
     * Return the token amount base on a given ethereum amount.
     */
    function getTokenAmountPerETH(uint256 ethAmount) internal 
        returns (uint256 resultAmount) 
    {
        uint256 coefficient;

        if (now < (startDate + 7 days)) {
            coefficient = 500000; // 20,000 Tokens
        } else if (now < (startDate + 14 days)) {
            coefficient = 666666; // 15,000 Tokens
        } else {
            coefficient = 1000000; // 10,000 Tokens
        }

        return ethAmount / coefficient ;
    }
}
