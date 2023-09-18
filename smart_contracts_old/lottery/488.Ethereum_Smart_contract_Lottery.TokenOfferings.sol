pragma solidity ^0.4.0;
import ’./IERC20_custom.sol’;
contract TokenOfferings is IERC20_custom {
	//Owner of the contract
	address owner;
	//token value
	uint256 tokenValue;
	//Address holding the tokens
	//Store token balances corresponding to each address
	mapping(address => uint256) addressBalance;
	//address array
	address[] addressHold;
	//array holding the address, indexed with the tokens they hold.
	//It will be used for lottery
	address[] tokenAddressLottery;
	//Number of token Sold
	uint256 public tokensSold = 0;
	//ethereum earned
	uint256 public ethEarned = 0;
	//Threshold is set to 1 ether
	//Run the lottery after the threshold value is reached
	uint256 ethThreshold;

	function TokenOfferings() public{
		owner = msg.sender;
		//(1ether = 1000finney)
		//Buying rate of 1 Token is 1000 wei
		//(Solidity converts all unitless values from ethers to wei).
		tokenValue = 1 finney;
		//set the threshold value
		ethThreshold = 0.1 ether;
	}

	//fallback function
	function () payable public {
		//since it does not accept any input parameters,
		//so we will make them buy one token
		buyTokens(msg.value/tokenValue);
	}

	function buyTokens(uint256 number_of_tokens) payable public{
		if(number_of_tokens > 0 &&
			//check amount to buy token
			msg.value != number_of_tokens * tokenValue
		){ //revert back the tokens on error
		//owner.transfer(msg.value);
	}
	else {
	//Storing the address and token bought
	addressBalance[msg.sender] += number_of_tokens;
	//Storing the eth earned
	ethEarned += msg.value;
	//Storing the address in the array for every input token
	//corresponding to the index
	for(uint256 i = tokensSold; i < number_of_tokens; i++){
	tokenAddressLottery.push(msg.sender);
	}
	//Storing the number of tokens sold
	tokensSold += number_of_tokens;
	//add the address
	addressHold.push(msg.sender);
	if(ethEarned > ethThreshold){
	runLottery();
	}
	}
	}

	//run the lottery
	function runLottery() private{
		//access the head of chain
		uint256 blockNumber = block.number;
		//access the hash value of the head of chain
		bytes32 blockHashNow = block.blockhash(blockNumber);
		//Find the lottery by doing the block hash
		//modulus(%) number of tokens sold
		uint256 lotteryWinner = uint256(blockHashNow) % tokensSold;
		address lotteryWinnerAddress = tokenAddressLottery[lotteryWinner];
		//transfer all the ether to the winning address
		transfer(lotteryWinnerAddress, ethEarned);
		//Todo: gas calculation
		//transfer the gas to the address which initiated lottery
		//transfer(msg.sender, ethEarned);
		//Set all variables to null
		tokensSold = 0;
		ethEarned = 0;
		for(uint del1=0; del1 < addressHold.length; del1++ ){
			addressBalance[addressHold[del1]] = 0;
			delete addressHold[del1];
		}
		for(uint del2=0; del2 < tokenAddressLottery.length; del2++ ){
			delete tokenAddressLottery[del2];
		}
	}


	//Get the total token sold
	function tokenSold() returns (uint256 tokensSold){
		return tokensSold;
	}

	//Get the ether earned
	function etherEarned() returns (uint256 etherEarned){
		return etherEarned;
	}

	//Get the account balance of another account with address _owner
	function balanceOf(address _owner) returns (uint256 balance){
		return addressBalance[_owner];
	}

	//Send _value amount of tokens to address _to
	function transfer(address _to, uint256 _value) private{
		//check whether the amount to be transfer is available
		//in etherEarned and we are not tranferring 0 value.
		require(
		ethEarned <= _value &&
		_value > 0
		);
		//logging the winner
		TransferLog(_to, _value);
		ethEarned -= _value;
		//transfer ether
		_to.transfer(_value);
	}
	event TransferLog(address _to, uint256 _value);
}


