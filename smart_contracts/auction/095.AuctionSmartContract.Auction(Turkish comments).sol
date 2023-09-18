// SPDX-License-Identifier: Unlicansed
pragma solidity ^0.8.7;

contract Auction {

    address payable public owner;

    // Auction'un başlama ve bitiş zamanlarını hesaplamamızda kullanılacak değişkenler.
    uint public startBlock;
    uint public endBlock;

    // Auction'un bilgileri, resimler vb. şeyleri blockchain'e kaydetmek pahalı olduğu için bu bilgileri kaydetmek için off chain bir çözüm kullanıyoruz.
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}  // Olabilecek durumları tanımladık.
    State public auctionState;  // Şu anki durumun nasıl olduğunu belirtebilmek için sonra kullanmak üzere bir değişken tanımladık fakat ona variable eklemedik daha.

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number; // "block.number" şu anki bloğun numarasını alıyor bu da ilk blok olmuş oluyor.
        endBlock = startBlock + 40320; // Her bir blok için ortalama 15 saniye geçiyormuş böylelikle bitiş tarihi hesaplandı
        ipfsHash = "";  // "I'm initializing it to an empty string" ???
        bidIncrement = 100000000000000000; // Bid arttırmak için 0.1 ether ödenmesi gerekiyor.
    }
    
    // "owner" ın yapamayacağı şeyleri belirlemek için tanımladık.
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    // Fonksiyonun çalışabilmesi için "startBlock" ve "endBlock" arasında olması gerektiğini tanımladık
    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    // Sadece owner'ın yapabileceği şeyler için modifier tanımladık.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Solidity'de iki sayıdan küçük olanı bulmak için bir fonskiyon yok o yüzden biz kendimize tanımlıyoruz.
    function min(uint a, uint b) pure internal returns(uint) {
        if(a <= b) {
            return a;
        } else {
            return b;
        }
    }

    // Sadece owner'ın kullanabileceği bir iptal etme fonksiyonu tanımladık.
    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    // İlk komplike kodlarımdan biri olduğu için kafam biraz karışık ve bazı yerleri yanlış açıklamış olabilirim.
    // Bu fonksiyon bizim ana fonksiyonumuz. Bid yapma işlemlerini halledicek.
    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running); // Başlayabilmesi için önceden tanımladığımız enum'u çağırdık.
        require(msg.value >= 100);  // Minimum bid'i 100 wei olarak ayarladık

        uint currentBid = bids[msg.sender] + msg.value; // Kullanıcının şu anki bid'ini görebilmesi için önceden tanımladığımız mapping'i çağırıp, önceki bid'ine şu an yaptığı bid'i ekleyen bir local variable tanımladık.
        require(currentBid > highestBindingBid); // En son bid'i en yüksek bid'den yüksek olması gerektiğini tanımladık.

        bids[msg.sender] = currentBid;  // mapping'i çağırarak şu anki bid'le fonksiyonu kullanan kişiyi birlieştirdik?

        // currentBid en yüksek bid'den yüksek olması gerekiyor.
        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }


    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock); // "||" = veya anlamına geliyor. Burada ya auction Canceled olmalıdır ya da block.number endBlock'dan büyük olmalıdır (belirlenen süre dolmalıdır) ki işlem gerçekleşsin.
        require(msg.sender == owner || bids[msg.sender] > 0);   // Ya owner bu fonksyionu çağırabilir ya da bid yapmış herhangi birisi.
    
        address payable recipient;  // Fonksiyonu kullanan adresi belirlemek için bunu tanımladık.
        uint value; //  Fonkisyonu kullananın value'sini belirlemek için bunu tanımladık.

        // Fonkiyonu çağıracak kişiler için ayrı ayrı senaryo oluşturduk.
        if(auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if(msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;  // Belki "value = bids[highestBidder] - highestBindingBid;" olara değiştirilmeli?
            } else {
                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        recipient.transfer(value);  // Fonksiyonu kullanan kişiye parasını yolladık?

        // Eğer fonksiyonu kullanan adresi bids[] mapping'inden çıkartmassak tekrar tekrar bu fonksinoyu kullanabilir ve kontrattaki bütün parayı sömürebilir.
        bids[recipient] = 0;    // Bu fonksiyonu kullanan kişi artık bidder olarak algılanmicak ve bu fonksiyonu tekrar çağıramayacak.
    }
}
