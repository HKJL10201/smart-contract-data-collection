// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity ^0.8.12;

//import fluid auction interface
import "fluiddao/contracts/interfaces/IAuctionHouse.sol";
import "fluiddao/contracts/AuctionHouse.sol";

//ERC721 receiver
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionBidder is ReentrancyGuard, Ownable {
	
	address immutable WETH2;
	address immutable FLUID;
	address immutable FLUIDNFT;
	address immutable sushiPool;
	address immutable treasury; 
	
	AuctionHouse immutable auctionHouse;

	constructor(
		address auctionHouseAddress,
		address sushiPoolAddress,
		address WETH2Address,
		address FLUIDTokenAddress,
		address FLUIDNFTTokenAddress,
		address DAOTreasury
	) {
		auctionHouse = AuctionHouse(auctionHouseAddress);
		sushiPool = sushiPoolAddress;
		WETH2 = WETH2Address;
		FLUID = FLUIDTokenAddress;
		FLUIDNFT = FLUIDNFTTokenAddress;
		treasury = DAOTreasury;
	}

	function onERC721Received(address operator, address from, uint256, bytes calldata) external pure returns (bytes4) {
		/*
		NEED TO FINALIZE TOKEN FORWARD UPON RECEIPT
		//require from = zeroAddress ==> only freshly minted tokens
		require(from == 0x0000000000000000000000000000000000000000, "Unsupported sender");
		//require operator = FluidNFTContract ==> only coming from the Fluid collection
		require(operator == FLUIDNFT, "Unsupported ERC721");
		//send token to treasury
		IERC721(FLUIDNFT).transferFrom(from, treasury, tokenId);
		*/
        return IERC721Receiver.onERC721Received.selector;
    }
	/*
	function topUp() public payable{
		
	}
	*/
	
	function withdrawToTreasury(
		uint256 _amount,
		address payable recipient
	) public 
	onlyOwner {
		require(address(this).balance >= _amount, "Not enough funds");
		require(recipient==treasury, "Not the treasury");
		recipient.transfer(_amount);
	}

	function withdrawAll(address payable recipient) public onlyOwner{
		withdraw(address(this).balance, recipient);
	}

	//returns the price in ETH of a FLUID token
	function getSushiPoolBalances() 
	public 
	view 
	returns (
		uint256 currentSushiReservesFluid,
		uint256 currentSushiReservesWeth
	){
		currentSushiReservesFluid = IERC20(FLUID).balanceOf(sushiPool);
		currentSushiReservesWeth = IERC20(WETH2).balanceOf(sushiPool);
	}

	function getFluidClaim() 
	public 
	view 
	returns (
		uint256 claim
	){
		claim = auctionHouse.rewardAmount(); //returns the current reward amount with 18 decimals
	}

	//To be called by keepers every 12h to settle current auction (if not done) and place reserve bid
	function performUpkeep() 
	public 
	nonReentrant {
		(
			uint256 _FLUIDnftId,
			uint256 _amount,
			uint256 _startTime,
			uint256 _endTime, ,
			bool _settled
		) = auctionHouse.auction();
		
		if(
			_startTime != 0
			&& !_settled
			&& block.timestamp >= _endTime
		){
			settleCurrent();
			//update auction parameters after settling and creating new
			(
				_FLUIDnftId,
				_amount,
				_startTime,
				_endTime, ,
				_settled
			) = auctionHouse.auction();
		}

		bidFloor(_FLUIDnftId, _amount);
	}

	function bidFloor(
		uint256 FLUIDnftId,
		uint256 currentBid
	) private {
		//compute bid floor price
		uint256 fluidClaim = getFluidClaim();
		(
			uint256 currentSushiReservesFluid,
			uint256 currentSushiReservesWeth
		) = getSushiPoolBalances();

		//Need to SafeMath this to avoid overflow issues
		uint256 bidValue = currentSushiReservesFluid * fluidClaim / currentSushiReservesWeth;

		require(currentBid < bidValue, "revert: current bid already higher than reserve price");
		require(address(this).balance > bidValue, "revert: not enough ETH in the contract");

		auctionHouse.createBid{value: bidValue}(FLUIDnftId);
	}

	function settleCurrent() private {
		auctionHouse.settleCurrentAndCreateNewAuction();
	}

	function withdrawToTreasury() public onlyOwner {
		//Send the on-hand $FLUID balance + Fluid-ids to the treasury address
		uint256 fluidBalance = IERC20(FLUID).balanceOf(address(this));
		IERC20(FLUID).transfer(treasury, fluidBalance);
	}
	
	receive() external payable {
    }
}