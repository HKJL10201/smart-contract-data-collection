// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Donate Matic; Donate. Gift Purpose can be stored as 'purpose' string in donations contract
//
//Track Donations;blockexplorer transaction info of contract address
// view donor list; blockexplorer display of addresses received from
//View Total; Get All Received Tokens
//withdraw tokens;
//set beneficiary; address = msg.sender
//emergency stop = disable donations button or metamask disconnect ?
//

contract Donate {
    // create organization
    address public owner;
mapping(campaignId =>uint ) public _Id;
mapping(campaign =>bool ) public ;
    event DonationMade(address donor, uint amount);
    event WithdrawalMade(
        address indexed recipient,
        uint amount,
        uint timestamp
    );

    struct Donation {
        address donor;
        uint amount;
        uint timestamp;
        bool isPaid;
    }

    struct Organization {
        address creator;
        string name;
        string about;
        uint goalAmount;
        uint currentAmount;
        uint createdTimestamp;
    }

    Organization[] public organizations;
    mapping(address => Donation[]) organizationsToDonation;

    constructor() {
        owner = msg.sender;
    }
function stopCampaign ( string ) public {  
require(org.creator == msg.sender, "You do not have permission");
        campaigns [id].active = false
}

    function createOrganization(
        string memory _name,
        string memory _about,
        uint _goalAmount
    ) public {
        require(bytes(_name).length > 0, "Organization name cannot be empty");
        require(_goalAmount > 0, "Goal amount must be greater than 0");

        Organization memory newOrganization = Organization({
            creator: msg.sender,
            name: _name,
            about: _about,
            goalAmount: _goalAmount,
            currentAmount: 0,
            createdTimestamp: block.timestamp
        });

        organizations.push(newOrganization);
    }

    // get organisations count
    function getOrganiationsCount() public view returns (uint) {
        return organizations.length;
    }

    // get single organisation
    function getOrganization(
        uint index
    ) public view returns (Organization memory) {
        require(index < organizations.length, "Invalid index");
        Organization memory org = organizations[index];
        return (org);
    }

    // Get all organisations
    function getAllOrganizations() public view returns (Organization[] memory) {
        return organizations;
    }

    // get organization address
    function getOrganiationsAddress(
        uint organizationIndex
    ) public view returns (address OrganizationAddress) {
        return organizations[organizationIndex].creator;
    }

    // Make Donation
    function makeDonation(uint organizationIndex) public payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        require(
            organizationIndex < organizations.length,
            "Invalid organization index"
        );

        Organization storage org = organizations[organizationIndex];
        require(
            org.currentAmount + msg.value <= org.goalAmount,
            "Donation exceeds goal amount"
        );

        org.currentAmount += msg.value;
        Donation memory newDonation = Donation(
            msg.sender,
            msg.value,
            block.timestamp,
            false
        );
        require(
            address(this).balance - org.currentAmount > 0,
            "Company has no donation"
        );
        newDonation.isPaid = true;
        organizationsToDonation[org.creator].push(newDonation);
        emit DonationMade(msg.sender, msg.value);
    }

    // Track tokens received
    function trackTokensReceived() public {}

    // Withdraw tokens
    function withdrawTokens(uint organizationIndex) public {
        require(
            organizationIndex < organizations.length,
            "Invalid organization index"
        );

        Organization storage org = organizations[organizationIndex];
        require(
            org.creator == msg.sender,
            "Only the organization creator can withdraw tokens"
        );

        uint amountToWithdraw = org.currentAmount;
        org.currentAmount = 0;

        payable(org.creator).transfer(amountToWithdraw);

        // Emit an event to indicate Ether has been withdrawn
        emit WithdrawalMade(org.creator, amountToWithdraw, block.timestamp);
    }

    // Get all received tokens
    function donationsMade(
        uint256 _index
    ) public view returns (Donation[] memory) {
        return organizationsToDonation[organizations[_index].creator];
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // Get donation link
    function getDonationLink(uint _index) public view returns (string memory) {
        require(_index < organizations.length, "Invalid index");
        string memory addressInString = toAsciiString(msg.sender);
        string memory donationLink = string(
            abi.encodePacked("https://example.com/donate/", addressInString)
        );

        return donationLink;
    }

    // get user balance
    function getUserBalance() external view returns (uint) {
        return msg.sender.balance;
    }
}

