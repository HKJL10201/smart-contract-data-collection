// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.1;

contract Trade
{
    address payable owner;
    address buyer_address;
    
    // contract owner specific modifier
    modifier onlyOwner ()
    {
        require(msg.sender == owner);
        _;
    }

    // buyer specific modifier 
    modifier onlyBuyer()
    {
        require(msg.sender == buyer_address);
        _;
    }

    // constructor to set the owner of the contract
    constructor (address buyer_add) public payable {
        owner = msg.sender;
        buyer_address = buyer_add;
    }
    
    // structure of the buyer
    struct Buyer
    {
        address addr;
        string name;
        bool init;
    }
    
    // structure of the current shipment
    struct Shipment
    {
        address payable courier;
        uint price;
        uint payment;
        address payer;
        uint date;
        uint delivery_date;
        bool init;
    }
    
    // structure of a particular order
    struct Order
    {
        string product;
        uint quantity;
        string location;
        uint seq_no;
        uint number;
        uint phone;
        uint price;
        uint payment;
        
        Shipment shipment;
        bool init;
    }
    
    // structure of the invoice
    struct Invoice
    {
        uint order_no;
        uint number;
        bool init;
    }
    
    // store orders mapping
    mapping (uint => Order) orders;
    
    // store invoices mapping
    mapping (uint => Invoice) invoices;
    
    // Events that depicts the flow in a smart contract
    uint order_seq;
    uint invoice_seq;
    
    event OrderSent (address buyer, string product, uint quantity, string location, uint order_no);
    event PriceSent (address buyer, uint order_no, uint product_price, uint delivery_charge, uint delivery_date);
    event Payment (address buyer, uint order_no, uint amount, uint phone, uint time_stamp);
    event InvoiceSent (address buyer, uint invoice_no, uint order_no, uint delivery_date, address courier);
    event OrderDelivered (address buyer, uint invoice_no, uint order_no, uint date, address courier);

    // Buyer request order to seller
    function sendOrder(string memory product, uint quantity, string memory location) public onlyBuyer payable 
    {

        order_seq++;
        
        orders[order_seq] = Order(product, quantity, location, order_seq, 0, 0, 0, 0, Shipment(address(0), 0, 0, address(0), 0, 0, false), true);

        emit OrderSent(msg.sender, product, quantity, location, order_seq);
    }

    // line up orders
    function query(uint seq_no) public view returns (address, string memory, uint, string memory, uint, uint, uint)
    {
        require(orders[seq_no].init);
        
        Order memory orderStruct;
        orderStruct = orders[seq_no];
        
        return (buyer_address, orderStruct.product, orderStruct.quantity, orderStruct.location, orderStruct.price, orderStruct.shipment.price, orderStruct.payment);
    }
    
    // seller sends the details of price and delivery_charges for the product
    function sendPrice(uint order_no, uint price, uint delivery_charge, uint delivery_date) public onlyOwner payable
    {
        require(orders[order_no].init);

        orders[order_no].price = price;
        orders[order_no].shipment.price = delivery_charge;
        orders[order_no].shipment.init = true;
        orders[order_no].shipment.date = delivery_date;

        emit PriceSent(buyer_address, order_no, price, delivery_charge, delivery_date);
    }

    // buyer pays the price of the product and delivery charge
    function sendPayment(uint order_no, uint phone_no) public onlyBuyer payable
    {
        require(orders[order_no].init);
        require(orders[order_no].price + orders[order_no].shipment.price == msg.value);

        orders[order_no].payment = msg.value;
        orders[order_no].phone = phone_no;

        emit Payment(buyer_address, order_no, msg.value, phone_no, now);
    }

    // seller sends the invoice to the carrier
    function sendInvoice(uint order_no, uint delivery_date, address payable courier) public onlyOwner payable
    {
        require(orders[order_no].init);
        invoice_seq++;

        invoices[invoice_seq] = Invoice(order_no, invoice_seq, true);

        orders[order_no].shipment.delivery_date = delivery_date;
        orders[order_no].shipment.courier = courier;

        emit InvoiceSent(buyer_address, invoice_seq, order_no, delivery_date, courier);
    }

    // fetch the invoice that is sent by the seller
    function getInvoice(uint invoice_no) view public returns (address buyer, uint order_no, uint delivery_date, address courier)
    {
        require(invoices[invoice_no].init);

        Invoice storage _invoice = invoices[invoice_no];
        Order storage _order = orders[_invoice.order_no];

        return (buyer_address, _order.number, _order.shipment.delivery_date, _order.shipment.courier);
    }
    
    // confirms item is delivered and payout seller and courier
    function delivery(uint invoice_no, uint time) public payable
    {
        require(invoices[invoice_no].init);

        Invoice storage _invoice = invoices[invoice_no];
        Order storage _order = orders[_invoice.order_no];

        require(_order.shipment.courier == msg.sender);

        emit OrderDelivered(buyer_address, invoice_no, _order.number, time, _order.shipment.courier);

        // payout amount to the seller
        owner.transfer(_order.payment);

        // payout delivery charges to the courier
        _order.shipment.courier.transfer(_order.shipment.payment);
    }   
}