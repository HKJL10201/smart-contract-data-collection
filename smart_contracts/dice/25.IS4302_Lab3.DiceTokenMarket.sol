pragma solidity ^0.5.0;
import "./Dice.sol";
import "./DiceToken.sol";

// Flow:
// user -(msg.sender, tx.origin)-> DiceTokenMarket -(msg.sender)-> (DiceToken -(msg.sender)-> ERC20)

/*
DiceTokenMarket execution / test:
1. use account A to deploy Dice contract
2. use account A to deploy DiceToken contract
3. use account A to deploy DiceTokenMarket contract with arg (Dice contract address, DiceToken contract address, 2)
4. use account A to execute Dice function add dice with arg (1,2) and value 1 ETH, becomes dice 0
5. use account A to execute Dice function transfer dice with arg (0, DiceTokenMarket address)
6. use account A to execute DiceTokenMarket function list dice with arg (0, 3)
7. use account B to execute DiceToken function getCredit with value 1 ETH
8. use account B to execute DiceTokenMarket function buy with arg (0)
9. use any account to check Dice variable dices with arg (0). Prev owner of dice should be DiceTokenMarket contract address and owner of dice should be account B address
10. use account A to execute DiceToken checkCredit function to see that balance has increased by 3 DT
11. use account B to execute DiceToken checkCredit function to see that balance has reduced by 5 DT to 95 DT
* 2 DT was commission fee for DiceMarketToken
*/


contract DiceTokenMarket {
    // DiceMarket contract define variable that is Dice object named diceContract
    Dice diceContract;

    DiceToken diceTokenContract;

    uint256 public commissionFee;
    // address that deploy DiceMarket / the seller is set as "actual" _owner of the dice in this contract
    address _owner = msg.sender;
    // map dice id to price
    mapping(uint256 => uint256) listPrice;
    // DiceMarket initialise with Dice object as 1st arg
    // constructor function called during deploy
      constructor(Dice diceAddress, DiceToken diceTokenAddress, uint256 fee) public {
        // DiceMarket contract variable Dice object (diceContract) is the 1st arg Dice object (diceAddress) passed into constructor function
        diceContract = diceAddress;

        diceTokenContract = diceTokenAddress;

        commissionFee = fee;
    }
    
    // list a dice for sale, price needs to be >= value + fee
    function list(uint256 id, uint256 price) public {
       require(msg.sender == diceContract.getPrevOwner(id), "only dice owner can set list dice and set price");
       listPrice[id] = price;
    }
    
    function unlist(uint256 id) public {
        require(msg.sender == diceContract.getPrevOwner(id), "only dice owner can unlist dice");
        listPrice[id] = 0;
    }

    // get price of dice
    function checkPrice(uint256 id) public view returns (uint256) {
        return listPrice[id];
    }

    // function diceTokenApprove() public {
    //     diceTokenContract.diceTokenApprove(msg.sender, address(this), 500);
    // }

    // function approve() public {
    //     diceTokenContract.approve(address(this), 500);
    // }

    // buyer call this function, buyer is msg.sender
    // buy the dice at the requested price
    function buy(uint256 id) public payable {
        require(listPrice[id] != 0, "only listed dice can be bought"); // is listed

        // buyer input value needs to be higher than price + fee
        // require(msg.value >= (listPrice[id] + commissionFee), "buyer input value must equal or exceed price + commissionFee"); // offered price meets minimum ask
        require(diceTokenContract.diceTokenMarketCheckCredit(msg.sender) >= (listPrice[id] + commissionFee), "buyer input value must equal or exceed price + commissionFee"); // offered price meets minimum ask

        // normal address is not payable
        // must define payable address
        // the dice owner is the recipient, used as payable address
        address payable recipient = address(uint160(diceContract.getPrevOwner(id)));
        
        diceTokenContract.diceTokenApprove(msg.sender, address(this), listPrice[id] + commissionFee); // only price + fee amount is approved for DiceMarketToken use from buyer account

        // diceTokenContract.diceTokenApprove(msg.sender, address(this), listPrice[id]);
        // diceTokenContract.approve(address(this),listPrice[id]);
        // diceTokenContract.transferFrom(msg.sender, recipient, listPrice[id]);
        diceTokenContract.diceTokenTransferFrom(msg.sender, address(this), recipient, listPrice[id]); // price amount is transferFrom buyer to seller

        // diceTokenContract.diceTokenApprove(msg.sender, address(this), commissionFee);
        // diceTokenContract.approve(address(this), commissionFee);
        // diceTokenContract.transferFrom(msg.sender, address(this), commissionFee);
        diceTokenContract.diceTokenTransferFrom(msg.sender, address(this), address(this), commissionFee); // fee amount is transferFrom buyer to this / DiceMarketToken contract

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
            // original is solidity standard method, caller to receive balalnce amount from this address
            // msg.sender.transfer(address(this).balance);
            
            diceTokenContract.transfer(msg.sender, diceTokenContract.checkCredit()); // assuming checkCredit() checks the DiceTokenMarket balance here ...      
    }
}
