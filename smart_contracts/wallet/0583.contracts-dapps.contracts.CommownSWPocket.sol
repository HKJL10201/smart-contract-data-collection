    // SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./CommownSWUtils.sol";

contract CommownSWPocket {

	address public owner; //CommownSW
	address public to; //To whom the pocket will be buy
	address public item; //Token address: ERC20, ERC721, ERC1155
	
	bytes public data; //Data on chain representing the transaction

	PocketStatus public pStatus;
	PocketType public pType;

    uint256 public totalAmount; //Total amount to reach
    uint256 public id; //Token Id: for ERC721, ERC1155
	uint256 public qty; //Token quantity: for ERC20, ERC721(bundles), ERC1155
	

	constructor(
		address _to,
		address _item,
		bytes memory _data,
		uint256 _totalAmount,
    	uint256 _id,
		uint256 _qty ,
		PocketType _pType
	) {
		owner = msg.sender;
		to=_to;
		item=_item;
		data=_data;
		totalAmount=_totalAmount;
		id=_id;
		qty=_qty;
		pType=_pType;
		pType = _pType;
	}

	function setStatus(PocketStatus _status) public {
		require(msg.sender == owner,"not able to call");
		pStatus=_status;
	}

}