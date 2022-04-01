pragma solidity ^0.4.18;


contract Staff {
	address owner; // адрес владельца контракта
	address platform; // адрес платформы

	// модификатор признака владельца контракта
	modifier isOwner {
	    require(msg.sender == owner);
	    _;
	}
	
	// признак директора
	modifier isDirector{ 		
		require(staff[msg.sender].token == 1);
		_; 
	}
	
	// признак директора или владельца контракта
	modifier isSetStaff{ 		
		require(staff[msg.sender].token == 1 || msg.sender == owner);
		_; 
	}
	
	// признак платформы
	modifier isPlatform {
	    require(msg.sender == platform);
	    _;
	}

	// структура описания сотрудника (Staff)
	struct StructStaff {
		uint timeVote; // время голосования сотрудником 
		uint timePropose; // время подачи предложения сотрудником 
		uint8 token; // токены сотрудника 0 - уволен, 1 - директора, 2 - сотрудник
	}
	
	// маппинг соответствыия структуры сотрудника к его адресу
	mapping (address => StructStaff) staff;
		
	// конструктор
	function Staff () public {
		owner = msg.sender;
	}
	
	// установить адрес платформы для голосований
	function setPlatform(address addr) public isOwner {
		require(addr != address(0));	
		platform = addr;		
	}	

	// добавление и изменение статуса сотрудника 
	function setStaffBalance(address addr, uint8 _token) public isSetStaff {
		require(addr != address(0));	
		staff[addr].token = _token;		
	}	
	
	// возвращает токен сотрудника
	function getStaffBalance(address addr) public view returns(uint8) {		
		return staff[addr].token;		
	}	

	// установка времени начала голосования
	function setTimeVote (address addr, uint _time) external isPlatform {
		require(addr != address(0));
		staff[addr].timeVote = _time;
	}

	// возврат времени начала голосования
	function getTimeVote(address addr) public view returns(uint) {
		return staff[addr].timeVote;
	}

	// установка времени начала подачи предложения
	function setTimePropose(address addr, uint _time) external isPlatform {
		require(addr != address(0));
		staff[addr].timePropose = _time;
	}

	// возврат времени начала подачи предложения
	function getTimePropose(address addr) public view returns(uint) {
		return staff[addr].timePropose;
	}

	// уничтожение контракта
	function kill() public isOwner {
		selfdestruct(owner);
	}
}
