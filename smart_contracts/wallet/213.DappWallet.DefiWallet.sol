//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DefiWallet {
    
	
	address constant LINK_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
  


	AggregatorV3Interface internal ethPriceFeed;
	AggregatorV3Interface internal linkPriceFeed;


    struct Balance {
        uint256 ethbal;
        uint256 lnkbal;
        uint256 usdtbal;
    }

    mapping(address => Balance) public users;
    mapping(address => uint256) private EthBalance;
	mapping(address => uint256) private LinkBalance;

	/**
     * Network: Rinkeby
	 * https://docs.chain.link/docs/ethereum-addresses/
     */
    constructor() {
        ethPriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
		linkPriceFeed = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
    
    }


   

	function getlatestEthPrice() public view returns (int)
	{
		(
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethPriceFeed.latestRoundData();
       
        return price;
	}

	function getlatestLinkPrice() public view returns (int)
	{
		(
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = linkPriceFeed.latestRoundData();
        
        return price;
	}
    
    
 

    //Deposit function


	function depositLink(uint256 amount) public{
		IERC20 lnk = IERC20(LINK_ADDRESS);

		require(lnk.balanceOf(msg.sender) >= amount, "Not enough LINK balance");

		lnk.transferFrom(msg.sender, address(this), amount);
		LinkBalance[msg.sender] += amount;

	}

	function depositEth() public payable{
		EthBalance[msg.sender] += msg.value;
        // Balance storage user = users[msg.sender];
        //  user.ethbal += msg.value;
	}



    //Withdrawal function

	function withdrawEth(uint256 amount) public {
       
       require(EthBalance[msg.sender] >= amount, "Not enough ETH balance");
		EthBalance[msg.sender] -= amount;
		payable(msg.sender).transfer(amount);
	}


	function withdrawLink(uint256 amount) public {

		IERC20 lnk = IERC20(LINK_ADDRESS);

		require(LinkBalance[msg.sender] >= amount, "Not enough LINK balance");
		LinkBalance[msg.sender] -= amount;
		lnk.transfer(msg.sender, amount);
	}
	


    function getEthBalance(address _userAddr) public view returns (uint256)
	{
		return EthBalance[_userAddr];
	}

	function getLinkBalance(address _userAddr) public view returns (uint256)
	{
		return LinkBalance[_userAddr];
	}


}
