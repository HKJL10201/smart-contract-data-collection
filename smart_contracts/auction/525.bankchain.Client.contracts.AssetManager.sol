pragma solidity ^0.6.0;

// Import AssetInterface contract to create instance of a NPA
import "./AssetInterface.sol";

// Import Ownable contract by OpenZeppelin to make only Owner access for various functions
import "./Ownable.sol";

contract AssetManager is Ownable{

    // example for bank address = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148

    //****-----Start of variable declaration-----****//

    enum EventType{EntityAdded,NPA_Created}

    struct bank{
        address payable bankAddress;
        string bankName;
    }

    //Mapping of different banks with index starting from 100
    mapping(uint=>bank) bankList;
    uint bankListIndex = 100;

    //Mapping of different sectors with index starting from 200
    mapping(uint=>uint) auctionList;
    uint auctionIndex = 200;

    //    Mapping of different eventType with index starting from 300
    mapping(uint=>string) eventTypes;
    uint eventIndex=300;

    //Structure to store the NPA contract instance and address of that instance for further interaction
    struct S_NPA
    {
        AssetInterface npa;
        address npaContract;
        uint bankId;
        uint auctionId;

    }
    //Mapping of different NPA structures with index starting from 400
    mapping(uint=>S_NPA) NPA_List;
    uint NPA_ListIndex=400;

    //Event to generate LOG of the NPA instance and it's address
    event eventState(string state,uint stateCode,uint id,string name,address npaAddress);

    event npaAddress(uint id, address npa);

    //****-----End of variable declaration-----****//

    function getNPA(uint _id) view public returns(uint id, address add){
        address npa =  NPA_List[_id].npaContract;
        return (_id,npa);
    }

    // function getBalance() view public returns(uint){
    //     return payable(address(this)).balance;
    // }

    function getBank(uint _id) view public returns(address,string memory){
        return (bankList[_id].bankAddress,bankList[_id].bankName);
    }

    // Add Bank function which first checks if the bank is already initialized or not, if initialized returns ID of that bank else emit event added
    function addBankIfNotExist(string memory _bankName) private onlyOwner returns(uint){
        bool bankExist = false;
        for(uint i = 100; i<bankListIndex; i++){
            if(keccak256(abi.encodePacked((_bankName))) == keccak256(abi.encodePacked(bankList[i].bankName))){
                bankExist=true;
                return i;
            }
        }
        if(!bankExist){
            bankList[bankListIndex].bankName=_bankName;
            emit eventState("Entity Added",uint(EventType.EntityAdded),bankListIndex,_bankName, address(0));
            bankListIndex++;
            return bankListIndex-1;
        }
    }

    // Add Sector function which first checks if the bank is already initialized or not, if initialized returns ID of that bank else emit event added
    function addAuctionIdIfNotExist(uint _auctionID) private onlyOwner returns(uint){
        bool auctionExist=false;
        for(uint j = 200; j<auctionIndex; j++){
            if(auctionList[j]==_auctionID){
                auctionExist=true;
                return j;
            }
        }
        if(!auctionExist){
            auctionList[auctionIndex]=_auctionID;
            emit eventState("Entity Added",uint(EventType.EntityAdded),auctionIndex,"Success", address(0));
            auctionIndex++;
            return auctionIndex-1;
        }
    }
    //
    //      Add Borrower function which first checks if the bank is already initialized or not, if initialized returns ID of that bank else emit event added
    function addEventTypeIfNotExist(string memory _eventName) private onlyOwner returns(uint){
        bool eventExist=false;
        for(uint k = 300; k<eventIndex; k++){
            if(keccak256(abi.encodePacked((_eventName))) == keccak256(abi.encodePacked(eventTypes[k]))){
                eventExist=true;
                return k;
            }
        }
        if(!eventExist){
            eventTypes[eventIndex]=_eventName;
            emit eventState("Entity Added",uint(EventType.EntityAdded),eventIndex,_eventName,address(0));
            eventIndex++;
            return eventIndex-1;
        }
    }

    function addNPA(string memory _bankName,string memory _assetOnAuction,uint _auctionID, string memory _eventType, string memory _city,
        uint _reservePrice,uint _EMD,uint _bidMultiplier, uint _timestamp) public onlyOwner{

        if(addAuctionIdIfNotExist(_auctionID)<auctionIndex){
            emit eventState("Already exist",uint(EventType.NPA_Created),NPA_ListIndex,"_borrowerName", address(0));
        }else{
            //  Creating AssetInterface contract of a NPA
            AssetInterface item = new AssetInterface(msg.sender, this, NPA_ListIndex, _assetOnAuction,
                _bankName, addAuctionIdIfNotExist(_auctionID), addEventTypeIfNotExist(_eventType),
                _city, _reservePrice, _EMD, _bidMultiplier, _timestamp);

            // Adding the NPA and address of that NPA to Structure
            NPA_List[NPA_ListIndex].npaContract = address(item);
            NPA_List[NPA_ListIndex].npa = item;
            NPA_List[NPA_ListIndex].bankId = addBankIfNotExist(_bankName);
            NPA_List[NPA_ListIndex].auctionId=_auctionID;
            emit eventState("NPA Created",uint(EventType.NPA_Created),NPA_ListIndex,"_borrowerName", address(item));
            NPA_ListIndex++;
        }
    }
}

