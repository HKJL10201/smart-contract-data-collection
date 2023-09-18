pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "./TicketFactory.sol";

// Storage
import "./storage/WtConstants.sol";
import "./storage/WtStorage.sol";

import "./Erc20TestToken.sol";
import "./OceanToken.sol";

//import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20interface {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract TicketMarket is WtStorage, WtConstants {

    TicketFactory public factory;
    Erc20TestToken public erc20Token;
    OceanToken public oceanToken;

    IERC20interface public ierc20;

    constructor(address _ticketFactoryContract, address _erc20TestTokenContract, address _oceanTokenContract) public {
        factory = TicketFactory(_ticketFactoryContract);
        erc20Token = Erc20TestToken(_erc20TestTokenContract);
        oceanToken = OceanToken(_oceanTokenContract);

        ierc20 = IERC20interface(_oceanTokenContract);
    }


    /***
     * @notice - Test function
     ***/
    function testFunc() public returns (bool) {
        return WtConstants.CONFIRMED;
    }




    /***
     * @notice - Called function
     ***/
    // @notice owner address of ERC721 token which is specified
    // @param _ticketId is tokenId
    function ownerOfTicket(uint _ticketId) public returns (address) {
        return factory._ownerOf(_ticketId);
    }
    

    // @notice test of inherited mint() from TicketFactory.sol
    function factoryMint(address _callAddress) public returns (bool) {
        //factory.mint();
        factory.mintOnExternalContract(_callAddress);
        return true;
    }
    
    // @notice test of inherited transferFrom() from TicketFactory.sol
    function factoryTransferFrom(address _from, address _to, uint256 _ticketId) public returns (bool) {
        factory._transferTicketFrom(_from, _to, _ticketId);
        return true;
    }


    /// @notice buys a certificate
    /// @param _ticketId the id of the ticket 
    function buyTicket(uint _ticketId) public {
        uint256 _purchasePrice = 0;
        _buyTicket(_ticketId, msg.sender, _purchasePrice);
    }
    

    function totalSupplyERC20() public view returns (uint256) {
        IERC20 erc20 = IERC20(oceanToken);
        return erc20.totalSupply();
        //return oceanToken._totalSupply();
    }
    

    function balanceOfERC20(address who) public view returns (uint256) {
        IERC20 erc20 = IERC20(oceanToken);
        return erc20.balanceOf(who);
    }
    


    function testTransferFrom(address from, address to, uint256 value) public returns(bool) {
        uint purchasePrice = 10;

        //IERC20 erc20 = IERC20(oceanToken);
        //erc20.transferFrom(from, to, value);
        
        ierc20.transferFrom(from, to, value);

        //return erc20Token._transferFrom(from, to, value);
        //oceanToken.transferFrom(from, to, value);
        return true;
    }
    

    function testTransfer(address to, uint256 value) public returns(bool) {
        //IERC20 erc20 = IERC20(oceanToken);
        //ERC20 erc20 = ERC20(erc20Token);
        //erc20.transfer(to, value);

        ierc20.transfer(to, value);

        //erc20Token.transfer(to, value);
        //oceanToken.transfer(to, value);
        return true;
    }





    /**********************
     * internal functions
    ***********************/

    function _buyTicket(uint _ticketId, address buyer, uint256 purchasePrice) public {
        //PurchasableTicket memory pTicket = getPurchasableTicket(_ticketId);
        ierc20.transfer(ownerOfTicket(_ticketId), purchasePrice);
        //IERC20 erc20 = IERC20(erc20Token);
        //erc20Token._transferFrom(buyer, ownerOfTicket(_ticketId), purchasePrice);
        //erc20Token.transferFrom(buyer, factory._ownerOf(_ticketId), purchasePrice);
        //erc20.transferFrom(buyer, factory.ownerOf(_ticketId), pTicket.PurchasePrice);
   
        factory._transferTicketFrom(ownerOfTicket(_ticketId), buyer, _ticketId);
        
        //_removeTokenAndPrice(_ticketId);

        //unpublishForSale(_ticketId);
    }

}
