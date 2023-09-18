pragma solidity ^0.4.17 ;

contract Lottery {
    address public manager ; // managerin adresi
    address[] public  players; // playerların adresi


    function Lottery() public {
        manager = msg.sender; // lottery methodu calistigi anda bu fonksiyon calisiyor ve managere enterleyen adamın adresini pompalıyor
        // ilk bu calısıcak cunku contract ile aynı addda fonksiyon


    }
    function enter() public payable {
        require(msg.value > .01 ether); // require boolean gibi bisi eger burası true olmuyorsa assagısına devam etmiyor

        players.push(msg.sender); // pushla beraber entere basan lavugun adresini players arrayinde sıradan yer veriyor


    }

    function random() private view returns (uint) {
       return uint( keccak256(block.difficulty, now , players)) ;
            // random olusuturuyor solidityde random fonksiyonu olmadıgı icin boyle bısı yapıyok block ve now global variablelar aynı msg gibi

    }

    function pickWinner() public restricted { // restricted olunca direk restrictedi yapıyoruz eger restricted ok ise buraya geri donup tamamlıyoruz


        uint index = random() % players.length; // random sayısını player length bölüp modulu atıyoruz KIND OF RANDOM
        players[index].transfer(this.balance) ; // this.balance yollanan tum etheri manager accountuna anlamına geliyo transfer ediyorus
        lastWinner = players[index];
        players = new address[](0); // tekrardan lotteryi hazırlamak icin players arrayini bosaltıyoruz 0 lık bi dinamik arraye döndoruyurouk

    }
    modifier restricted {  // herhangi fonksiyonla eslestiginde fonksiyonu sanki burdaki alt cizginin oraya yapıstırmıs gibi ilk kendi icini yapıyor eger ok  ise geri kalana devamke.
        require(msg.sender == manager) ;
        _;
    }
    function getPlayers() public view returns  (address[]) {
        return players ; // butun oyuncuları gormek icin yapıyoruz bunu8

    }

}
