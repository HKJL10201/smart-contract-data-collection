// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
contract demo{

    enum status{
        Not_Started , 
        Started , 
        Cancelled , 
        Completed
    }

    struct trip{
        string place ;
        uint budget; //(per person);
        address person;
        uint agreeVotes;
        uint disagreeVotes;
        uint noOfVotes;
        //uint collectedFund;
        bool IsConfirmed;
        status tripStatus;  
    }
    
    address[] public group;
    uint TotalTrips = 0;
    mapping(uint => trip) public AllTrips;
    mapping(uint => mapping(address => bool)) public userVote;
    mapping(address => uint) public userAmount;
    mapping(address => bool) public userShare;
    mapping(uint => trip) public PastTrips;
    trip st;
    trip public selectedTrip;
    uint public selectedTripId;
    address public owner;
    bool isTripSelected;
    bool isTripStarted;
    event tripStarted(string message);
    event tripCancelled(string reason);
    event tripCompleted(string review);
    uint public totalPastTrips;

    constructor( ){
        owner = msg.sender;
        group.push(msg.sender);
    }

    function addGroupMember(address[] memory people) public {
        require(people.length > 0 , "No people to enter");
        for(uint i = 0 ; i < people.length ; i++){
            require(people[i] != address(0) , "Enter valid address ");
            group.push(people[i]);
        }
    }

    function checkUserExists(address u) internal view returns(bool){
        for(uint i = 0 ; i < group.length ; i++){
            if(group[i] == u){
                return true;
            }	
        }
        return false;	
    }

    function checkTripExists(string memory name) internal view returns(bool){
        for (uint i = 0; i < TotalTrips; i++) {
            uint tripId = i; // Assuming trip IDs start from 0
            trip memory currentTrip = AllTrips[tripId];
                if (keccak256(bytes(currentTrip.place)) == keccak256(bytes(name))) {
                    return true; // Trip with the given name already exists
                }
        }               
        return false;
        
    }

    function getStatusString(status _status) internal pure returns (string memory) {
        if (_status == status.Not_Started) return "Not Started";
        if (_status == status.Started) return "Started";
        if (_status == status.Cancelled) return "Cancelled";
        if (_status == status.Completed) return "Completed";
        revert("Invalid status");
    }


    function getTripStatus(uint tripId) public view returns(string memory ){
        require(tripId <= TotalTrips -1 , "Invalid Tripid");
        return getStatusString(AllTrips[tripId].tripStatus);
    }

    function planTrip(string memory _place, uint _budget ) public {
        require(bytes(_place).length>0 , "Enter valid name");
        require(_budget >= 1 ether , "Enter valid budget value");
        require(checkUserExists(msg.sender) , "You are not a part of group");
        require(!checkTripExists(_place) , "Trips already exists");
        status tstatus = status.Not_Started;
        trip memory newTrip = trip(_place , _budget , msg.sender , 0, 0, 0, false,tstatus);
        // string memory tripStatus =  getStatusString(newTrip.tripStatus);
        AllTrips[TotalTrips ] = newTrip;
        TotalTrips++;   
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function Vote(uint tripId , uint v) public{
        require(checkUserExists(msg.sender) , "You are not a part of group");
        require(v == 0 || v == 1 , "Enter 1 to agree/yes or Enter 0 to disagree/no");
        trip storage t = AllTrips[tripId ];
        require(compareStrings(getStatusString(AllTrips[tripId].tripStatus), "Not Started"), "You can't vote for the started, cancelled, or completed trips");
        require(bytes(t.place).length > 0 , "Trip doesn't exists");
        require(msg.sender != t.person , "you can't vote for the trip you created");
        require(t.budget > 0 , "Trip budget should be greater than 0");
        require(userVote[tripId][msg.sender] == false , "Already voted");
        require(t.IsConfirmed == false, "Trip  has already been confirmed");
        if( v == 0){
            t.noOfVotes++;
            t.disagreeVotes++;
        }
        else{
            t.noOfVotes++;
            t.agreeVotes++;
        }
        userVote[tripId][msg.sender] = true;
    }

    function isVotingCompleted() public view returns(bool){
        trip memory t ;
        uint counter = 0;
        for(uint i = 0 ; i < TotalTrips ; i++){
            t = AllTrips[i];
            if(t.noOfVotes == group.length-1){
                counter++;
            }
        }
        if(counter == TotalTrips)
            return true;

        return false;
    }

    function CheckTripDestination() public returns(uint ,trip memory){
        require(checkUserExists(msg.sender) , "You are not a part of group");
        require(isVotingCompleted() , "Voting is not ended");
        require(TotalTrips > 0 , "No trip added");
        trip memory t = AllTrips[0];
        uint confirmedTripId = 0;
        uint highestVotes = 0;
        for(uint i = 0 ; i < TotalTrips ; i++){
            if(AllTrips[i].agreeVotes > highestVotes){
                highestVotes = AllTrips[i].agreeVotes;
                t = AllTrips[i];
                confirmedTripId = i;
            }
        }
        isTripSelected = true;
        selectedTripId = confirmedTripId;
        trip storage t2 = AllTrips[selectedTripId];
        t2.IsConfirmed = true;
        selectedTrip = t;
        return (confirmedTripId, AllTrips[confirmedTripId]);
    }

    function startTrip() public  {
        require(checkUserExists(msg.sender) , "You are not a part of group");
        require(isVotingCompleted() , "Voting is not ended");
        require(TotalTrips > 0 , "No trip added");
        require(isTripSelected , "No trip selected till NoW!");

        trip storage t = AllTrips[selectedTripId];
        require(address(this).balance >= t.budget * group.length, "Wallet balance does't match trip budget");
        require(msg.sender == t.person , "Only the trip leader can start trip");
        emit tripStarted("Trip has been started");
        t.tripStatus = status.Started;
        getTripStatus(selectedTripId);
        isTripStarted = true;
    }

    function cancelTrip() public{
        require(checkUserExists(msg.sender) , "You are not a part of group");
        require(isVotingCompleted() , "Voting is not ended");
        require(isTripSelected , "No trip selected till NoW!");
        require(!isTripStarted , "Trip has already started");
        require(address(this).balance > 0 , "Not having balance in the wallet");
        
        trip storage t = AllTrips[selectedTripId];
        require(msg.sender == t.person , "Only the trip leader can cancel trip");
        uint value ;
        address payable person;
        for(uint i = 0 ; i < group.length; i++){
            if(userShare[group[i]] == true){
                value = userAmount[group[i]];
                person = payable(group[i]);
                person.transfer(value);
            }
        }
        t.tripStatus = status.Cancelled;
        emit tripCancelled("Due to some of the weather issue. The trip has been cancelled");    
    }

    function payYourShare() public payable {
        require(checkUserExists(msg.sender), "You are not a part of the group");
        require(selectedTrip.budget > 0, "No trip selected");
        //require(userVote[selectedTripId][msg.sender] == true, "You have not voted");
        require(msg.value >= selectedTrip.budget, "Enter valid amount");
        trip memory t = AllTrips[selectedTripId];
        if(t.person != msg.sender){
            require(userVote[selectedTripId][msg.sender] == true, "You have not voted");
        }
        userVote[selectedTripId][msg.sender] = true;
        userShare[msg.sender] = true;
        userAmount[msg.sender] = msg.value;
    }

    function completeTrip() public {
        require(checkUserExists(msg.sender) , "You are not a part of group");
        require(isVotingCompleted() , "Voting is not ended");
        require(isTripSelected , "No trip selected till NoW!");
        require(isTripStarted , "Trip has not started yet");
        trip storage t = AllTrips[selectedTripId];
        t.tripStatus = status.Completed;   
        PastTrips[totalPastTrips] = t;
        totalPastTrips++;
    }
}
