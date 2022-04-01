pragma solidity >=0.5.13 < 0.7.0;

contract Wallet{
    address owner;
    address public finance;
    
    uint256 public financeValue;
    
    struct userDetails {
        uint256 amount;
        string name;
        string grade;
    }
    
    mapping(address => userDetails) public employee;
    
    constructor() public{
        owner=msg.sender;
    }
    
    function financeDept(address _addr) public{
        finance=_addr;
    }
    
    function financeDeposite() public payable{
        require(finance==msg.sender);
        financeValue+=msg.value;
    }
    
    function financeWithdraw(uint256 _val) public payable{
        require(finance==msg.sender);
        msg.sender.transfer(_val*1 ether);
        financeValue-=_val;
    }
    
    function createEmployee(string memory _name, string memory _grade) public{
        require(finance!=msg.sender);
        require(owner!=msg.sender);
        require(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked((''))));
        require(keccak256(abi.encodePacked(_grade)) == keccak256(abi.encodePacked('1A')) || 
        keccak256(abi.encodePacked(_grade)) == keccak256(abi.encodePacked('2A')) || 
        keccak256(abi.encodePacked(_grade)) == keccak256(abi.encodePacked('3A')) || 
        keccak256(abi.encodePacked(_grade)) == keccak256(abi.encodePacked('4A')) || 
        keccak256(abi.encodePacked(_grade)) == keccak256(abi.encodePacked('5A')));
        employee[msg.sender].name=_name;
        employee[msg.sender].grade=_grade;
    }
    
    function employeeDeposite() public payable{
        require(finance!=msg.sender);
        require(owner!=msg.sender);
        if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('1A')))){
            require(msg.value<=(30* 1 ether));
            employee[msg.sender].amount+=msg.value;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('2A')))){
            require(msg.value<=(20* 1 ether));
            employee[msg.sender].amount+=msg.value;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('3A')))){
            require(msg.value<=(10* 1 ether));
            employee[msg.sender].amount+=msg.value;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('4A')))){
            require(msg.value<=(5* 1 ether));
            employee[msg.sender].amount+=msg.value;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('5A')))){
            require(msg.value<=(2* 1 ether));
            employee[msg.sender].amount+=msg.value;
        }
    }
    
    function employeeWithdraw(uint256 _val) public payable{
        require(finance!=msg.sender);
        require(owner!=msg.sender);
        if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('1A')))){
            _val=_val * 1 ether;
            require(_val<=(30* 1 ether));
            require(employee[msg.sender].amount>=_val);
            msg.sender.transfer(_val);
            employee[msg.sender].amount-=_val;
        }

        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('2A')))){
            _val=_val * 1 ether;
            require(_val<=(20* 1 ether));
            require(employee[msg.sender].amount>=_val);
            msg.sender.transfer(_val);
            employee[msg.sender].amount-=_val;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('3A')))){
            _val=_val * 1 ether;
            require(_val<=(10* 1 ether));
            require(employee[msg.sender].amount>=_val);
            msg.sender.transfer(_val);
            employee[msg.sender].amount-=_val;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('4A')))){
            _val=_val * 1 ether;
            require(_val<=(5* 1 ether));
            require(employee[msg.sender].amount>=_val);
            msg.sender.transfer(_val);
            employee[msg.sender].amount-=_val;
        }
        
        else if(keccak256(abi.encodePacked((employee[msg.sender].grade))) == keccak256(abi.encodePacked(('5A')))){
            _val=_val * 1 ether;
            require(_val<=(2* 1 ether));
            require(employee[msg.sender].amount>=_val);
            msg.sender.transfer(_val);
            employee[msg.sender].amount-=_val;
        }
    }
}
