pragma solidity ^ 0.4.17;

contract CampaignFactory{
    address[] deployedCampaigns;

    function createCampaign(uint minimum) public {
        address newCampaign = new Campaign(minimum,msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]){
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request{
        string description;
        uint value;
        address recipient;
        bool complete;
        mapping(address => bool) voters;
        uint votes;
    }

    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public shareholders;
    uint public shareholdersCount;
    Request[] public requests;

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    function Campaign(uint minimum, address creator) public{
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable{
        require(msg.value > minimumContribution);
        shareholders[msg.sender] = true;
        shareholdersCount++;
    }

    function createRequest(string description, uint value, address recipient) public restricted{
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            votes: 0
        });
        requests.push(newRequest);
    }

    function approveRequest(uint index) public{
        Request storage request = requests[index];
        require(shareholders[msg.sender]);
        require(!requests[index].voters[msg.sender]);
        request.voters[msg.sender] = true;
        request.votes++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        
        require(request.votes > (shareholdersCount/2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns(uint,uint,uint,uint, address){
        return (
            minimumContribution,
            this.balance,
            requests.length,
            shareholdersCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint){
        return requests.length;
    }
}