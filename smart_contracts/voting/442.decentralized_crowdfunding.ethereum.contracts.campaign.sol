pragma solidity ^0.4.17;

/**
 * @title Campaign Factory
 */
contract CampaignFactory {
    // Array that stores all of the addresses
    // of deployed campaigns.
    address[] public deployedCampaigns;

    /**
     * @dev Function that creates a new
     * campaign from the Campaign contract.
     * @param _minimum amount needed to be able
     * to contribute to the newly created campaign.
     */
    function createCampaign(uint _minimum) public {
        address newCampaign = new Campaign(_minimum, msg.sender);
        
        deployedCampaigns.push(newCampaign);
    }

    /**
     * @dev Function that returns the addresses of all
     * deployed campaigns.
     * @return array of deployed campaign addresses.
     */
    function getDeployedCampaigns() public view returns(address[]) {
        return deployedCampaigns;
    }
}

/**
 * @title Campaign
 */
contract Campaign {

    /**
     * New struct type storing the
     * requests that the manager address
     * will submit for approval of how to
     * use contributions.
     */
    struct Request {
        // Describes why the request
        // is being created.
        string description;
        // Amount of money that the
        // manager wants to send to
        // the vendor.
        uint value;
        // Address that the money will
        // be sent to.
        address recipient;
        // True if request has already
        // been processed.
        bool complete;
        // Variable to keep count of 'yes'
        // votes for a particular Request.
        uint approvalCount;
        // Mapping storing what each contributor
        // voted on the Request.
        mapping(address => bool) approvals;
    }
    /**
     * Array storing all of the requests
     * that have been submitted.
     */
    Request[] public requests;

    /**
     * Address of person who created the
     * campaing contract.
     */
    address public manager;
    /**
     * Uint of the mimimum amount that
     * can be accepted in this campaign.
     */
    uint public minimumContribution;
    /**
     * Mapping storing whether or not an
     * addresses has contributed.
     */
    mapping(address => bool) public approvers;
    /**
     * Uint to keep count of the number of
     * "yes" votes.
     */
    uint public approversCount;
    
    /**
     * @dev Guarantees msg.sender is the same
     * address that is stored under
     * the manager variable.
     */
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    /**
     * @dev The constructor function that
     * sets the msg.sender as the value for
     * the previously declared manager variable
     * and the uint to the declared minimumContribution
     * variable.
     * @param _minimum the uint to be saved under
     * minimumContribution.
     * @param _creator the address of the campaign
     * creator.
     */
    function Campaign(uint _minimum, address _creator) public {
        manager = _creator;
        minimumContribution = _minimum;
    }

    /**
     * @dev Function that will serve to accept
     * contributions in the form of ether.
     */
    function contribute() public payable {
        require(msg.value > minimumContribution);
        
        approvers[msg.sender] = true;
        approversCount++;
    }

    /**
     * @dev Function that creates a new struct of
     * the Request type.
     * @param _description descriptor for the
     * Request being created.
     * @param _value amount of money being managed.
     * @param _recipient address of the recipient
     * of _value.
     */
    function createRequest(string _description, uint _value, address _recipient) public restricted {
        // Creating a new variable that will have a
        // Request named newRequest.
        Request memory newRequest = Request({
            description: _description,
            value: _value,
            recipient: _recipient,
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
    }

    /**
     * @dev Function that approves a request
     * made by the manager address.
     * @param _index index of the request being
     * approved.
     */
    function approveRequest(uint _index) public {
        Request storage request = requests[_index];

        // Verifyind the msg.sender can approave
        // and hasn't already done so.
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        // Make sure that msg.sender cannot
        // approve same request again. Increase
        // requests total approval count.
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    /**
     * @dev Function that finalizes a request
     * made by the manager address and sends the
     * funds to the recipient address.
     * @param _index index of the request being
     * finalized.
     */
    function finalizeRequest(uint _index) public restricted {
        Request storage request = requests[_index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    /**
     * @dev Function that returns data stored in the
     * contract.
     */
    function getSummary() public view returns(
        uint, uint, uint, uint, address
        ) {
        return (
            minimumContribution,
            this.balance,
            requests.length,
            approversCount,
            manager
        );
    }

    /**
     * @dev Function that returns the number of requests
     * stored in the contract.
     */
    function getRequestsCount() public view returns(uint) {
        return requests.length;
    }
}