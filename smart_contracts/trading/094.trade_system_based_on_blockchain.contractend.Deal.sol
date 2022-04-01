// this contract is used to store the information of Deal
// not Responsible for receving or sending eth

// pragma solidity >=0.4.21 <0.7.0;
pragma solidity 0.6.1;

contract Deal {

    uint uid;
    address payable seller;
    address payable buyer;
    uint price;
    uint amount;
    string fromWhere;
    string toWhere;
    uint dealLaunchTime;
    uint dealPayTime;
    uint dealFinishedTime;

    enum State { Created, Locked, Release, Inactive }
    State state;

    // launch Deal
    constructor(
        uint _uid,
        address payable _seller,
        address payable _buyer,
        uint _price,
        string memory _fromWhere,
        string memory _toWhere,
        uint _amount,
        uint _dealLaunchTime
    ) public payable {
        uid = _uid;
        seller = _seller;
        buyer = _buyer;
        price = _price;
        amount = _amount;
        fromWhere = _fromWhere;
        toWhere = _toWhere;
        dealLaunchTime = _dealLaunchTime;
        state = State.Created;
        
    }

    // abort deal function ,
    // can execution before finished
    function abortDeal(
        address payable _caller
    ) public returns (uint){
        if ((state != State.Created) && (state != State.Locked))return 2;
        if (_caller != buyer) return 3;

        if(state == State.Locked){
            state = State.Inactive;
            return 1;
        }
        state = State.Inactive;
        return 0;
    }

    
    // get payment function
    function getPayment(
        address payable _buyer,
        uint _dealPayTime
    ) public payable returns (uint){
        if(state != State.Created) return 1;
        if(buyer != _buyer) return 2;
        state = State.Locked;
        dealPayTime = _dealPayTime;
        return 0;
    }

    // finish deal
    // only after getPayment
    function finishConfirm(
        address payable _buyer,
        uint _receivedTime
    ) public returns (uint) {
        if (state != State.Locked)return 1;
        if (_buyer != buyer)return 2;
        state = State.Release;
        dealFinishedTime = _receivedTime;
        // require(1==2, 'debug point 2');
        // buyer.transfer(price);
        return 0;
    }


    // return state
    function stateInfo() public view returns (uint) {
        if(state == State.Created) {
            return 0;
        }else if(state == State.Locked){
            return 1;
        }else if(state == State.Release){
            return 2;
        }else if(state == State.Inactive){
            return 3;
        }else {
            return 4;
        }
    }

    function fromWhereInfo() public view returns (string memory) {
        return fromWhere;
    }

    function toWhereInfo() public view returns (string memory) {
        return toWhere;
    }

    function sellerInfo() public view returns (address payable) {
        return seller;
    }

    function buyerInfo() public view returns (address payable) {
        return buyer;
    }

    function priceInfo() public view returns (uint) {
        return price;
    }

    function uidInfo() public view returns (uint) {
        return uid;
    }

    function amountInfo() public view returns (uint) {
        return amount;
    }

    function dealLaunchTimeInfo() public view returns (uint) {
        return dealLaunchTime;
    }

    function dealPayTimeInfo() public view returns (uint) {
        return dealPayTime;
    }

    function dealFinishedTimeInfo() public view returns (uint) {
        return dealFinishedTime;
    }
}


