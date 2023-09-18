pragma solidity ^0.5.0;
import "./Dice.sol";

contract DiceMarket {
    // DiceMarket contract define variable that is Dice object named diceContract
    Dice diceContract;
    uint256 public commissionFee;
    // address that deploy DiceMarket / the seller is set as "actual" _owner of the dice in this contract
    address _owner = msg.sender;
    // map dice id to price
    mapping(uint256 => uint256) listPrice;
    // DiceMarket initialise with Dice object as 1st arg
    // constructor function called during deploy
      constructor(Dice diceAddress, uint256 fee) public {
        // DiceMarket contract variable Dice object (diceContract) is the 1st arg Dice object (diceAddress) passed into constructor function
        diceContract = diceAddress;
        commissionFee = fee;
    }
    
    // list a dice for sale, price needs to be >= value + fee
    function list(uint256 id, uint256 price) public {
       require(msg.sender == diceContract.getPrevOwner(id));
       listPrice[id] = price;
    }
    
    function unlist(uint256 id) public {
        require(msg.sender == diceContract.getPrevOwner(id));
        listPrice[id] = 0;
    }

    // get price of dice
    function checkPrice(uint256 id) public view returns (uint256) {
        return listPrice[id];
    }

    // buyer call this function, buyer is msg.sender
    // buy the dice at the requested price
    function buy(uint256 id) public payable {
        require(listPrice[id] != 0); // is listed
        // buyer input value needs to be higher than price + fee
        require(msg.value >= (listPrice[id] + commissionFee)); // offered price meets minimum ask

        // normal address is not payable
        // must define payable address
        // the dice owner / seller is the recipient, used as payable address
        address payable recipient = address(uint160(diceContract.getPrevOwner(id)));
        // solidity standard method <address>.transfer to transfer amount from the caller to the <address> of the recipient
        recipient.transfer(msg.value - commissionFee); // transfer (price-commissionFee) to real owner
        // Dice object custom function to transfer dice to buyer
        diceContract.transfer(id, msg.sender);
    }

    function getContractOwner() public view returns(address) {
        return _owner;
    }

    // seller of the dice call this function
    function withdraw() public {
        // if caller is seller of the dice
        if (msg.sender == _owner)
            // solidity standard method, caller to receive balalnce amount from this DiceMarket address
            msg.sender.transfer(address(this).balance);
    }
}
