// This project we will create in solidity version 0.5.3 
pragma solidity >=0.4.25 <0.6.0;

contract AuctionController{
    Auction[] public auctions;
    function CreateAuction (
        uint _biddingTime,
        string memory _title,
        uint _initPrice,
        uint _minIncrePrice,
        string memory _description
        ) public {
        Auction newAuction = new Auction(msg.sender,
                                        _biddingTime, 
                                        _title, 
                                        _initPrice, 
                                        _minIncrePrice, 
                                        _description);
        auctions.push(newAuction);
    }
    
    function GetAllAuctions() public view returns(Auction[] memory){
        return auctions;
    }
}

contract Auction{
    enum StateType {Running, Finished}
    StateType public State;

    // Owner of the auction
    address payable public owner;
  
    address payable public highestBidder;
    uint public highestPrice;
    
    uint public biddingTime;               // Cal by second
    uint public endTime;                   // Cal by second
  
    // List Item properties
    string public title;
    uint public initPrice;
    uint public minIncrePrice;
    string public description;

    // Allowed withdrawals of previous bids
    mapping(address => uint) public pendingWithDrawals;
    address[] public bidders;

    // constructor function
    constructor (
        address payable _owner,
        uint _biddingTime,
        string memory _title,
        uint _initPrice,
        uint _minIncrePrice,
        string memory _description
    ) public {
        owner = _owner;
        require(_biddingTime > 0, "Bidding time must > 0");
        biddingTime = _biddingTime;
        title = _title;
        initPrice = _initPrice;
        minIncrePrice = _minIncrePrice;
        description = _description;
        endTime = now + _biddingTime;
        State = StateType.Running;
    }

    function GetRemainingTime() public view returns (uint){
        if (now >= endTime){
            return 0;
        }
        if (State == StateType.Finished){
            return 0;
        }
        return (endTime - now);
    }
    
    function GetWinningBidder() public view returns (address){
        require(State == StateType.Finished || now >= endTime, "Auction hasn't finished.");
        return highestBidder;
    }
    
    function GetWinningPrice() public view returns (uint){
        require(State == StateType.Finished || now >= endTime, "Auction hasn't finished.");
        return highestPrice;
    }

    function Bid() public payable returns(bool){
        require(State == StateType.Running, "Owner has finished the auction.");
        
        if (now >= endTime){
            revert("Auction has finished.");
        }

        if (owner == msg.sender){
            revert("Owner can't bid the auction.");
        }
        
        if (msg.value < 0){
            revert("Value must greater than 0.");
        }
        
        if (highestPrice == 0 && msg.value < initPrice){
            revert("Invalid value.");
        }
        
        uint newPrice = pendingWithDrawals[msg.sender] + msg.value;
        
        if (newPrice < highestPrice + minIncrePrice){
            revert("Value must greater or equal than highestPrice + minIncrePrice.");
        }
        
        if (pendingWithDrawals[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        pendingWithDrawals[msg.sender] = newPrice;
        highestBidder = msg.sender;
        highestPrice = newPrice;
        
        return true;
    }

    function CancelOrFinish() public{
        uint amount = pendingWithDrawals[msg.sender]; 
        if (highestBidder == msg.sender){
            revert("The highest bidder can't leave auction.");
        }
        else if (owner == msg.sender){
            pendingWithDrawals[highestBidder] = 0;
            owner.transfer(highestPrice);
            State = StateType.Finished;
        }
        else if (amount > 0){
            pendingWithDrawals[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
        else{
            revert("You can't cancel or finish the auction.");
        }
    }

    // Chuc nang nay can nhieu gas do transfer() duoc call qua nhieu => de that bai
    // function Finish() public {
    //     require(State == StateType.Running);
        
    //     if (owner != msg.sender){
    //         revert();
    //     }
        
    //     State = StateType.Finished;
    //     pendingWithDrawals[highestBidder] = 0;
    //     owner.transfer(highestPrice);
    //     for (uint i = 0; i < bidders.length; i++){
    //         uint amount = pendingWithDrawals[bidders[i]];
    //         if (amount > 0){
    //             pendingWithDrawals[bidders[i]] = 0;
    //             bidders[i].transfer(amount);
    //         }
    //     }
    // }
    
    function GetState() public view returns(uint){
        if (now < endTime){
            return 0;
        }
        if (State == StateType.Running){
            return 0;
        }
        if (State == StateType.Finished){
            return 1;
        }
        return 1;
    }
    
    function GetAllBidders() public view returns (address[] memory){
        return bidders;
    }
    
    function GetNumberBidders() public view returns (uint) {
        return bidders.length;
    }
    
    function GetAuctionInfor() public view returns (address, string memory, uint, uint, string memory, uint){
        return (owner, title, initPrice, minIncrePrice, description, biddingTime);
    }
}