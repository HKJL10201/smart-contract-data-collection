//suppose there is a great grandfather who has some fortunes in the form of ether and when he dies then the fortune has to be given to his daughter
//hence we need to check whether he has died or not that is "deceased" hence the variable for it
pragma solidity ^0.8;

contract Will
{

address owner;// here the owner variable is address type as it returns the address
uint fortune;  //the amount that will be transferred
bool deceased;//check for deceased using bool type that is true or false    

constructor() payable public //constructor is the function that is invoked to deploy the smart contract
{                            //payable is a keyword used to make sure to send and receive ethers that is make things payable to perform   

//now here in constructor we are defining the objects as done above
owner=msg.sender; //msg sender represents address that is being called
fortune=msg.value; //msg value tells us how much ether is being sent
deceased=false; //if the grandfather didnt die
}
//create a modifier so the only person who can call the contract is the owner and we use modifiers to addons over the function
modifier onlyOwner
{
    require(msg.sender==owner); //here we are using this modifier add on usuing require which means it is like a confitional statement something like if else where condition is put and so the condition here is that the one who is calling the function should be the owner
    _; //here this underscore says that if the condition is true then only go ahead to functions and execute otherwise if msg sender is not the owner then stop
}
//create modifier so that we only allocate funds if friend's gramps deceased
modifier mustbeDeceased
{
    require(deceased==true); //here we are using this modifier add on usuing require which means it is like a confitional statement something like if else where condition is put and so the condition here is that the the gramps must have deceased so ==true
    _;
} //inorder to put condtions in a smart contract we can use modifiers as done
//now if gramps are deceased then we need to send over the fortune basically ethers to the daughters and sons and kids basically , hence in order to do it we need their wallet address where the fund can be transferred so , we need a list of wallet adresses and for that we make an array
address payable[] familyWallets;//here we need list of wallet address so the type will be address and array, also payable as to send or receive ethers we need payable 
    //map throught inheritance that is it is like a loop which will traverse that for what address or wallet how much amount has to be transferred
mapping(address=>uint) inheritance; //that is it is used to map values with one another hence for every address what value that is uint
//set inheritance for each address that is set the or take input the value using a function for a wallet address type and what amount will it be given

function setInheritance(address payable wallet, uint amount) public onlyOwner  //hence for this wallet address or wallet which will receive the ether so payable and what amount will be given that is what amount will be mapped with this specific address wallet depends on the inut that will be given using this function
{//the only one who gets to decide the amount to be given is with the owner that is the you are the owner here who will give amount so modifier onlyOwner
//once the wallet will be enetered then we will enter it in the list of wallets that in the array that was created using push so
familyWallets.push(wallet);
inheritance[wallet]=amount;//now to map the wallet adress with the amount 
}
//PAY EACH FAMILY MAMEBER BASED ON THEIR WALLET ADDRESS that now a function that will use inheritance mapping abpve to actually pay
function payout() private mustbeDeceased //here we are invoking the modifier so that this function payout works only if the gramps is deceased also we want to keep it private
{ //in the previous function we have only defined how mapping will happen incase of transfer of money by taking the inputs but the transfer is not yet done so in this function we need a loop which can go to every address wallet while iterating and paying ether that is amount as
uint i;
for(i=0;i<familyWallets.length;i++)
{
   familyWallets[i].transfer(inheritance[familyWallets[i]]);//transferring the funds from contract address to receiver address
//that is in family wallet of i that is first wallet entered we have to transfer amount using inheritance as it will map the amount with the wallet in the familyWallet[i] that is in that specific address wallet or at that index mapping the amount
}
}
//now since the deceased is actually set to false initially the contract will never pay out so we need to make a function which makes the deceased as true and then calls for payout function in order to ditribute the fortune
function hasdeceased() public onlyOwner //here only owner (lkike a bank or somethinh) gets to decide what happens after its deceased so bring that modifier 
{
deceased=true;
payout();
}
}
//note the account is selected that is 1st one and if u set 30 value and ether and then deploy note that 30 ethers will be allocated to the smart contract which for this can be used to allocate tot he children
//note that the wei is smallest unit of ether and 1ether= 1 eigtheen zeros so this is the thing
//now in the deployed contracts, from the list of accounts copy and address, put the address back to the 1st one and in address paste the adress that u copied along with the amount in wei so for 1ether to send to the copied and pasted address write amount 1and eighteen zeros this way from the allocated 30 ethers 1 ether will go to the copied address if hasdeceased is triggered that is amount will be transferred only then money will be deducted and the remaining allocated amout to the other copied address
//address copied is pasted in double quotations also keep the track of code along with depoyed contratcs