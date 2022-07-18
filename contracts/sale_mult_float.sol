// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./IBEP20.sol";
import "./Ownable.sol";

/**
polygon-test
Transaction sent: 0x2cf09fb4227f886109e4935af9615eca7b574b8f535a355a30f4792009176545
  Gas price: 1.500000033 gwei   Gas limit: 1238176   Nonce: 9
  Sale_mult_float.constructor confirmed   Block: 27172934   Gas used: 1125615 (90.91%)
  Sale_mult_float deployed at: 0x94A680d466e99D48e353e98E94A1277F48186dCf

Verification complete. Result: Pass - Verified */

contract Sale_mult_float is Ownable {

    address public USDT; //address of the token which creates the price of the security token
    address public SECURITIES; //address of the security token

    uint256 public basePrice; // price of the secutity token in USD*10
    uint8 public baseDecimals; //decimals of the base price
    address public manager;
    bool public status; // isActive

    struct Order {
        uint256 securities;
        uint256 USDT;
        address token; // address of the token with which security was bought
        string orderId;
        address payer;
    }

    Order[] public orders;
    uint256 public ordersCount;

    event BuyTokensEvent(address buyer, uint256 amountSecurities, address swapToken);

    constructor(address _USDT, address _securities) {
        USDT = _USDT;
        SECURITIES = _securities;
        manager = _msgSender();
        ordersCount = 0;
        basePrice = 425; //=42,5 USDT
        baseDecimals = 8;
        status = true;
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
    
    /// @notice price and its decimals of the secutity token in USDT
    /// @param priceInUSDT price of Security in USDT
    /// @param priceDecimals decimals for price in USDT
    function setPrice(uint256 priceInUSDT, uint8 priceDecimals) public onlyManager {
        basePrice = priceInUSDT;
        baseDecimals = priceDecimals;
    }

    /// @notice swap of the token to security. 
    /// Security has 0 decimals. Formula round amount of securities to get to a whole number
    /// @dev make swap, create and write the order of the operation, emit BuyTokensEvent
    /// @param amountUSDT amount of token to buy securities
    /// @param swapToken address of the token to buy security. 
    /// Has to be equal to the USDT in price, in other way formula doesn't work
    /// @return true if the operation done successfully
    function buyToken(uint256 amountUSDT, address swapToken, string memory orderId) public onlyActive returns(bool) {
        
        uint256 scaledTokenAmount = _scaleAmount(amountUSDT, IBEP20(swapToken).decimals(), baseDecimals);
        uint256 amountSecurities = scaledTokenAmount / basePrice;
        Order memory order;
        IBEP20(swapToken).transferFrom(_msgSender(), address(this), amountUSDT);
        require(IBEP20(SECURITIES).transfer(_msgSender(), amountSecurities), "transfer: SEC error");

        order.USDT = amountUSDT;
        order.securities = amountSecurities;
        order.token = swapToken;
        order.orderId = orderId;
        order.payer = _msgSender();
        orders.push(order);
        ordersCount += 1;

        emit BuyTokensEvent(_msgSender(), amountSecurities, swapToken);
        return true;
    }
    
    /// @notice Owner of the contract has an opportunity to send any tokens from the contract to his/her wallet    
    /// @param amount amount of the tokens to send (18 decimals)
    /// @param token address of the tokens to send
    /// @return true if the operation done successfully
    function sendBack(uint256 amount, address token) public onlyOwner returns(bool) {
        require(IBEP20(token).transfer(_msgSender(), amount), "Transfer: error");
        return true;
    }

    /// @notice function count and return the amount of security to be gotten for the proper amount of tokens 
    /// Security has 0 decimals. Formula round amount of securities to get to a whole number    
    /// @param amountUSDT amount of token you want to spend
    /// @param swapToken address of token you want to use for buying security
    /// @return token , securities -  tuple of uintegers - (amount of token to spend, amount of securities to get)    
    function buyTokenView(uint256 amountUSDT, address swapToken) public view returns(uint256 token, uint256 securities) {
        uint256 scaledAmountUSDT = _scaleAmount(amountUSDT, IBEP20(swapToken).decimals(), baseDecimals);
        uint256 amountSecurities = scaledAmountUSDT / basePrice;
        return (
        amountUSDT, amountSecurities
         );
    }

    /// @notice the function reduces the amount to the required decimals      
    /// @param _amount amount of token you want to reduce
    /// @param _amountDecimals decimals which amount has now
    /// @param _decimals decimals you want to get after scaling
    /// @return uint256 the scaled amount with proper decimals
    function _scaleAmount(uint256 _amount, uint8 _amountDecimals, uint8 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_amountDecimals < _decimals) {
            return _amount * (10 ** uint256(_decimals - _amountDecimals));
        } else if (_amountDecimals > _decimals) {
            return _amount / (10 ** uint256(_amountDecimals - _decimals));
        }
        return _amount;
    }

}
