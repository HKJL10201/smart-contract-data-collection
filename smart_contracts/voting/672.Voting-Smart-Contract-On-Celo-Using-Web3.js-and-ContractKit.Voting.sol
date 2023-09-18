//import all dependencies
const Web3 = require("web3");
const ContractKit = require("@celo/contractkit");

//set up the network
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

//connect to your already deployed contract
const ContractAbi = [
	{
		"inputs": [
			{
				"internalType": "string",
				"name": "proposalName",
				"type": "string"
			}
		],
		"name": "addCandidate",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			}
		],
		"name": "delegate",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "voter",
				"type": "address"
			}
		],
		"name": "giveRightToVote",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "proposal",
				"type": "uint256"
			}
		],
		"name": "vote",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [],
		"name": "chairperson",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"name": "proposals",
		"outputs": [
			{
				"internalType": "string",
				"name": "name",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "voteCount",
				"type": "uint256"
			},
			{
				"internalType": "bool",
				"name": "added",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "voters",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "weight",
				"type": "uint256"
			},
			{
				"internalType": "bool",
				"name": "voted",
				"type": "bool"
			},
			{
				"internalType": "address",
				"name": "delegate",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "vote",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "winnerName",
		"outputs": [
			{
				"internalType": "string",
				"name": "winnerName_",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "winningProposal",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "winingProposal_",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
];
const ContractAddress = '0x6C432a07d2C7C5ABbbBB47E408C5eCc40Eea0C4b';
const contracts = new kit.web3.eth.Contract(ContractAbi, ContractAddress);

//set up your account

const PRIVATE_KEY = '0xa27790f81bc74d9159bb5f8c71261b8aaec6f6b0c26bed5b4fabe281cea38964';

const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);


//sign transactions from our first account
kit.connection.addAccount(account.privateKey);
kit.defaultAccount = account.address;


//a second account for testing some smart contract  functions
const account2 = '0x89563f2535ad834833c0D84CF81Ee335867b8e34';



//begin calling the functions in you smart contract

//add a new candidate 
async function addCandidate() {
    console.log('Adding candidate...');
    const gasPrice = await kit.web3.eth.getGasPrice();
    const tx = await contracts.methods.addCandidate("Candidate A").send({ from: account.address, gas: 2000000, gasPrice: gasPrice });
    console.log('Transaction hash:', tx.transactionHash);
    console.log('Candidate added!');
}

//chairperson to give voters right to vote
async function giveRightToVote(voterAddress) {
    console.log('Giving right to vote to:', account2);
    const gasPrice = await kit.web3.eth.getGasPrice();
    const tx = await contracts.methods.giveRightToVote(account2).send({ from: account.address, gas: 2000000, gasPrice: gasPrice });
    console.log('Transaction hash:', tx.transactionHash);
    console.log('Right to vote given!');
}


//vote for the first candidate using the indexxed position
async function vote(proposalIndex) {
    console.log('Voting for proposal:', 0);
    const gasPrice = await kit.web3.eth.getGasPrice();
    const tx = await contracts.methods.vote(proposalIndex).send({ from: account.address, gas: 2000000, gasPrice: gasPrice });
    console.log('Transaction hash:', tx.transactionHash);
    console.log('Vote submitted!');
}


 //delegate your voting rights to another
async function delegate() {
    console.log('Delegating vote to:',account2 );
    const gasPrice = await kit.web3.eth.getGasPrice();
    const tx = await contracts.methods.delegate(account2).send({ from: account.address, gas: 2000000, gasPrice: gasPrice });
    console.log('Transaction hash:', tx.transactionHash);
    console.log('Vote delegated!');
}


//retrieve the winning candidate
async function getWinnerName() {
    console.log('Fetching winner name...');
    const winnerName = await contracts.methods.winnerName().call();
    console.log('Winner name:', winnerName);
    return winnerName;
}


//retrieve the winning Candidate Index 
async function getWinningProposal() {
    console.log('Fetching winning proposal index...');
    const winningProposalIndex = await contracts.methods.winningProposal().call();
    console.log('Winning proposal index:', winningProposalIndex);
    return winningProposalIndex;
}



// Example usage:
(async function () {
    await addCandidate();
   	await giveRightToVote(account.address);
    await vote(0);
	await delegate();
    await getWinningProposal();
    await getWinnerName();
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
