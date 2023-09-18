// pragma experimental ABIEncoderV2
pragma solidity ^0.8.7;

contract TransplantMatching {
    
    uint256 public patientCount = 0;
    mapping(uint256 => Patient) public patients;
    
    uint256 public donorCount = 0;
    mapping(uint256 => Donor) public donors;

    struct Patient {
        uint256 id;
        string firstname;
        string lastname;
        string organ;
        string bloodtype;
        string height;
        string weight;
        string status;
    }
    
    struct Donor {
        uint256 id;
        string firstname;
        string lastname;
        string organ;
        string bloodtype;
        string height;
        string weight;
        string status;
    }
    
    function validateOrgan(string memory _organ) public pure returns (string memory) {
        string memory _status;
        if (bytes(_organ).length > 0) {
            // In real life, would use oracle to access healthcare institution data for validation
            _status = 'eligible';
        }
        return _status;
    }

    function getPatientCount() public view returns (uint256) {
        return patientCount;
    }

    function getDonorCount() public view returns (uint256) {
        return donorCount;
    }
    
    function addPatient(string memory _firstname, string memory _lastname, string memory _organ, string memory _bloodtype, string memory _height, string memory _weight) public {
        
        // Set parameters as required
        require(bytes(_firstname).length > 0);
        require(bytes(_lastname).length > 0);
        require(bytes(_organ).length > 0);
        require(bytes(_bloodtype).length > 0);
        require(bytes(_height).length > 0);
        require(bytes(_weight).length > 0);
        
        string memory _status = validateOrgan(_organ);
        
        // Check if requirements satisfied
        if (bytes(_firstname).length > 0 && bytes(_lastname).length > 0 && bytes(_organ).length > 0 && bytes(_bloodtype).length > 0 && bytes(_height).length > 0 && bytes(_weight).length > 0) {
            patientCount++;
            patients[patientCount] = Patient(patientCount, _firstname, _lastname, _organ, _bloodtype, _height, _weight, _status);
        }
    }
    
    function addDonor(string memory _firstname, string memory _lastname, string memory _organ, string memory _bloodtype, string memory _height, string memory _weight) public {
        
        // Set parameters as required
        require(bytes(_firstname).length > 0);
        require(bytes(_lastname).length > 0);
        require(bytes(_organ).length > 0);
        require(bytes(_bloodtype).length > 0);
        require(bytes(_height).length > 0);
        require(bytes(_weight).length > 0);
        
        string memory _status = validateOrgan(_organ);
        
        // Check if requirements satisfied
        if (bytes(_firstname).length > 0 && bytes(_lastname).length > 0 && bytes(_organ).length > 0 && bytes(_bloodtype).length > 0 && bytes(_height).length > 0 && bytes(_weight).length > 0) {
            donorCount++;
            donors[donorCount] = Donor(donorCount, _firstname, _lastname, _organ, _bloodtype, _height, _weight, _status);
        }
    }
    
    function getAllPatients(uint256 _index) public view returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        return (patients[_index].firstname, patients[_index].lastname, patients[_index].organ, patients[_index].bloodtype, patients[_index].height, patients[_index].weight, patients[_index].status);
    }
    
    function getAllDonors(uint256 _index) public view returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        return (donors[_index].firstname, donors[_index].lastname, donors[_index].organ, donors[_index].bloodtype, donors[_index].height, donors[_index].weight, donors[_index].status);
    }
    
}