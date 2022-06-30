// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./IBEP20.sol";
import "./Ownable.sol";

contract Sale is Ownable {

    address public USDT;
    address public USDC;
    address public SECURITIES;
    address public chosenCurrency;

    uint256 public basePrice;
    address public manager;
    bool public status;

    struct Order {
        uint256 securities;
        uint256 USDT;
        string orderId;
        address payer;
    }

    Order[] public orders;
    uint256 public ordersCount;

    event BuyTokensEvent(address buyer, uint256 amountSecurities);

    constructor(address _USDT, address _USDC, address _securities) {
        USDT = _USDT;
        USDC = _USDC;
        SECURITIES = _securities;
        manager = _msgSender();
        ordersCount = 0;
        basePrice = 425;
        status = true;
        chosenCurrency = _USDT;
    }

    modifier onlyManager() {
        require(_msgSender() == manager, "Wrong sender");
        _;
    }

    modifier onlyActive() {
        require(status == true, "Sale: not active");
        _;
    }

    function changeManager(address newManager) public onlyOwner {
        manager = newManager;
    }

    function changeStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function setPrice(uint256 priceInUSDT) public onlyManager {
        basePrice = priceInUSDT;
    }

    function chooseUSDC() public returns(address) {
        chosenCurrency = USDC;
        return chosenCurrency;
    }

    function chooseUSDT() public returns(address) {
        chosenCurrency = USDT;
        return chosenCurrency;
    }

    function buyToken(uint256 amountUSD, string memory orderId) public onlyActive returns(bool) {
        uint256 amountSecurities = (amountUSD*10 / basePrice) / (10**(IBEP20(chosenCurrency).decimals()));
        Order memory order;
        IBEP20(chosenCurrency).transferFrom(_msgSender(), address(this), amountUSD);
        require(IBEP20(SECURITIES).transfer(_msgSender(), amountSecurities), "transfer: SEC error");

        order.USDT = amountUSD;
        order.securities = amountSecurities;
        order.orderId = orderId;
        order.payer = _msgSender();
        orders.push(order);
        ordersCount += 1;

        emit BuyTokensEvent(_msgSender(), amountSecurities);
        return true;
    }

    function sendBack(uint256 amount, address token) public onlyOwner returns(bool) {
        require(IBEP20(token).transfer(_msgSender(), amount), "Transfer: error");
        return true;
    }

    function buyTokenView(uint256 amountUSD) public view returns(uint256 token, uint256 securities) {
        uint256 amountSecurities = (amountUSD*10 / basePrice) / (10**(IBEP20(chosenCurrency).decimals()));
        return (
        amountUSD, amountSecurities
         );
    }

}

