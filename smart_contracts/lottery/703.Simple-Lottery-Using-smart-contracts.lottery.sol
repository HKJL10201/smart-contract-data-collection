pragma solidity 0.5.1;

contract lottery{
    
    
    struct Person{
        address id;
        string firstName;
        string lastName;
        bool isValid;
        bytes32 hash;
        uint value;
    }
    string[] hashes;
    address payable[] ids;
    address payable wallet;
    uint peopleCount  = 0;
    uint placedBid = 0;
    uint checkedValue = 0;
    mapping(address => Person) people;
    uint256 startTime;
    bool timeHasExceeded;

    event Register(
    string _firstname,
    string _lastname,
    address addr
    );
        
    event Cheating(
        string cheat
    );
    
    event TimeExceeded(
        string str,
        uint startTime,
        uint time
    );

    event Match(
        string str
    );
        
    event winner(
        address addr,
        string str
    );

    event bidPlaced(
        address addr,
        bytes32 hash
    ); 

    event ProtocolViolated(
        string str
    );

    
    constructor(address payable _wallet) public{
        wallet = _wallet;
    }

    function stringToUint(string memory s) internal returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function bytestoStr(bytes32 _bytes32) internal pure returns (string memory out) {

    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
        }
    out = string(bytesArray);
    return out;
    }
   
    ///Register for lottery
    function registerForLottery(string calldata firstName, string calldata lastName)  external payable {
        require(people[msg.sender].isValid == false,"You have already registered for the lottery");
        require(msg.sender != wallet,"Sorry, the contractor cannot participate");
        require(msg.value == 30 ether,"Please provide 30 ether to participate where 10 is the bid amount and 20 is deposit");
        require(peopleCount < 3, "Maximum number of participant reached i.e. 3");
        people[msg.sender] = Person(msg.sender,firstName,lastName,true,0x0,3);
        ids.push(msg.sender);
        peopleCount++;
        emit Register(firstName,lastName,msg.sender);
    }
    
    function bidValueInHash(bytes32  _hash) external {
        require(people[msg.sender].isValid == true,"You have not registered for the lottery");
        require(people[msg.sender].hash == 0x0,"You have already placed a bid");
        people[msg.sender].hash = _hash;
        placedBid ++;
        emit bidPlaced(msg.sender,_hash);
    }
    
    function startOpeningBids() public{
        require(msg.sender == wallet,"Only the owner can call this method");
        startTime = now;
    }

    
    
    function checkHash(string memory value,string memory randomValue) internal returns(bool){
        uint inputValue = stringToUint(value);
        if (inputValue >= 3){
            for(uint i =0;i<ids.length;i++){
            if(msg.sender != ids[i]){
                address payable temp = ids[i];
                temp.transfer(40 ether);
            }
        }
        emit ProtocolViolated("Valid inputs: 0,1,2. You have been penalized for violating the protocol.");
        selfdestruct(msg.sender);
        }
        require(inputValue < 3, "The input value has to be between 0, 1 or 2");
        require(people[msg.sender].isValid == true,"You have not registered for the lottery");
        require(placedBid == 3,"Cannot call openBids untill all participant have placed their hashed bid value");
        require(people[msg.sender].value == 3,"You have already sent your value and do not have to send it again");
        string memory value_randomValue = string(abi.encodePacked(value,randomValue));
        bytes32 temp =keccak256(abi.encodePacked(value_randomValue));
        if (keccak256(abi.encodePacked(temp)) != keccak256(abi.encodePacked(people[msg.sender].hash))){
            return true;
        }
        people[msg.sender].value = inputValue;
        checkedValue++;
        return false;
    }
    
    function openBids(string calldata _value,string calldata _randomValue) external payable{
        require(startTime > 0 ,"You cannot start this function before calling startOpeningBids");
        uint256 timeOfEntry;
        if(now > startTime + 5 minutes){
            timeHasExceeded = true;
            timeOfEntry = now;
        }
        if( timeHasExceeded || checkHash(_value,_randomValue)){
            for(uint i =0;i<ids.length;i++){
            if(msg.sender != ids[i]){
                address payable temp = ids[i];
                temp.transfer(40 ether);
            }
        }
        if(timeHasExceeded){
            emit TimeExceeded("You did not reveal your value within 5 minutes and hence you are being penalized",startTime,timeOfEntry);
        }
        else{
            emit Cheating("Cheating detected as your value does not match your hash provided earlier. You have been penalized and as a result 20 ether from your wallet has been given to other participants and the lottery has been terminated");
        }
        selfdestruct(msg.sender);
        }
        emit Match("Your hash provided earlier matches the value, you do not have to submit it again");
    }
    
    function calculateLotteryWinner() external payable{
        require(checkedValue == 3,"All values have not been submitted yet, you can only call this method after all parties have provided their input");
        uint total = 0;
        for (uint i = 0;i<3;i++){
            total += people[ids[i]].value;
        }
        total = total%3;
        emit winner(ids[total],"Congratulations, you have won");
        for(uint i = 0 ; i < 3 ; i++){
            if(ids[i] != ids[total]){
                ids[i].transfer(1 ether* 20);
            }
        }
        selfdestruct(ids[total]);
    }
}