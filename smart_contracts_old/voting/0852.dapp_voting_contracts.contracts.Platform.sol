pragma solidity ^0.4.18;

import "./SafeMath.sol";

interface Staff {
	function getStaffBalance(address addr) external view returns(uint8);
	function setTimeVote (address addr, uint time) external;
	function getTimeVote(address addr) external view returns(uint);
	function setTimePropose(address addr, uint time) external;
	function getTimePropose(address addr) external view returns(uint);
}

contract Platform {
	using SafeMath for uint;

	Staff staffContract;
	address owner; 
	address[] public proposalSenders; // Массив адресов, приславших предложения

	mapping (address => Proposal) platformProposals; // Массив предложений

	uint public platformProposalEnd; //Время окончания подачи предложений
	uint public platformVoteEnd; //Время окончания голосования

	uint public platformVoteModificator; //Время на голосование
	uint public platformProposalModificator; //Время на подачу предложений

	PlatformState platformState = PlatformState.CLOSED; // Состояние платформы при запуске - закрыта

	enum ProposalState { VOTE, QUORUM }
	enum PlatformState { OPENED, CLOSED }

	struct Proposal {
		string title; //Название
		string description; //Описание
		uint money; //Запрашиваемое кол-во эфира
		uint positiveVote; //Количесто голосов за
		uint totalVote; //Общее количество голосов
		uint endTime; // Время окончания голосования за данное предложение
		ProposalState proposalState; //Состояние предложения
	}

	modifier isOwner {
		require(msg.sender == owner);
		_;
	}

	modifier isStaff {
		require(staffContract.getStaffBalance(msg.sender) == 2);
		_;
	}

	modifier isDirector {
		require(staffContract.getStaffBalance(msg.sender) == 1);
		_;
	}

	// Проверяем когда сотрудник в последний раз голосовал
	modifier canVote {
        require(now > platformProposalEnd);
		require(staffContract.getTimeVote(msg.sender) < platformVoteEnd);
		_;
	}

	// Проверяем когда сотрудник в последний раз подавал предложение
	modifier canPropose {
		require(staffContract.getTimePropose(msg.sender) < platformProposalEnd);
		_;
	}

	function setStaffContract(address _address) public isOwner {
		staffContract = Staff(_address);
	}

	function Platform() public {
		owner = msg.sender;
		platformVoteModificator = 1 days;
		platformProposalModificator = 1 hours;
	}

	function addProposal(string _title, string _description, uint _amount) public isStaff canPropose {
		if (platformProposalEnd > now && platformState == PlatformState.OPENED) {
			proposalSenders.push(msg.sender);
			staffContract.setTimePropose(msg.sender, platformProposalEnd);

			//Перезапись/очищение всех полей предыдущего предложения
			platformProposals[msg.sender].title = _title;
			platformProposals[msg.sender].description = _description;
			platformProposals[msg.sender].money = _amount;
			platformProposals[msg.sender].positiveVote = 0;
			platformProposals[msg.sender].totalVote = 0;
			platformProposals[msg.sender].endTime = platformVoteEnd;
			platformProposals[msg.sender].proposalState = ProposalState.VOTE;
		} else {
			platformState = PlatformState.CLOSED;
		}
	}

	//голосование
	function vote(address _address, bool _vote) public isStaff canVote {
		require(msg.sender != _address); //нельзя голосовать за свой
		//Проверка что предложение не "архивное"
		require(platformProposals[_address].endTime == platformVoteEnd);

		staffContract.setTimeVote(msg.sender, platformVoteEnd);
		// Если время не истекло, то голосуем
		if (platformVoteEnd > now) {
			// true - увелечение голосов за и общее, false - только общее
			if (_vote == true) {
				platformProposals[_address].positiveVote = platformProposals[_address].positiveVote.add(1);
				platformProposals[_address].totalVote = platformProposals[_address].totalVote.add(1);
			} else {
				platformProposals[_address].totalVote = platformProposals[_address].totalVote.add(1);
			}
		} else {
			// Иначе проверяем на кворум
			checkQuorum(_address);
		}
	}

	//отправка денег на контракт
	function depositeMoney() public payable isDirector {
		require(msg.value >= 1 ether);
	}

	//выбор победителя
	function selectWinner(address _address) public isDirector {
		require(platformProposals[_address].endTime == platformVoteEnd);
		require(platformProposals[_address].proposalState == ProposalState.QUORUM); //проверка что кворум выполнен
		delete proposalSenders;
		platformState = PlatformState.CLOSED;
		_address.transfer(platformProposals[_address].money); //трансфер победителю
	}

	// "Открытие" платформы
	function openPlatform() public isDirector {
		delete proposalSenders;
		platformState = PlatformState.OPENED;
		platformProposalEnd = now + platformProposalModificator;
		platformVoteEnd = platformProposalEnd + platformVoteModificator;
	}
	
	function setVotePeriod(uint _time) public isDirector {
	    platformVoteModificator = _time;
	}
	
	function setProposalPeriod(uint _time) public isDirector {
	    platformProposalModificator = _time;
	}


	//Просмотр баланса
	function showBalance() public view returns(uint) {
		return address(this).balance;
	}

	//Получение общедоступхных значений предложения
	function showProposal(address _address) public view returns(
		string, //Название
		string, //Описание
		uint, //запрошенный Эфир
		uint, //Время окончания голосования
		uint8) //состояние предложения
		{ 
		return (
				platformProposals[_address].title,
				platformProposals[_address].description,
				platformProposals[_address].money,
				platformProposals[_address].endTime,
				uint8(platformProposals[_address].proposalState)
			);
		}

		//Получения статистики для Директора
		//Количество голосов за и общее
		function showProposalStatistic(address _address) public view isDirector returns(uint, uint) {
			return (platformProposals[_address].positiveVote, platformProposals[_address].totalVote);
		}

		//Получение состояния платформы
		function getPlatformState() public view returns(uint8) {
			return uint8(platformState);
		}
		
		//Получение адресов тех кто отправил предложения
		function getProposalSender(uint _number) public view returns(address) {
		    return proposalSenders[_number];
		}

		//Проверка на достижение кворума в 70% и изменение состояния
		function checkQuorum(address _address) public {
			require(now > platformVoteEnd);
			uint full = platformProposals[_address].positiveVote.mul(100);
			uint quorum = full.div(platformProposals[_address].totalVote);

			if (quorum >= 70)
				platformProposals[_address].proposalState = ProposalState.QUORUM;
			else
				platformProposals[_address].proposalState = ProposalState.VOTE;
		}

		//Удаление контракта
		function kill() public isOwner {
			selfdestruct(owner);
		}

}