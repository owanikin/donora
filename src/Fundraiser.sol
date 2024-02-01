// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract Fundraiser {
    using PriceConverter for uint256;

    address public fundOwner;
    uint256 public totalFunds;

    AggregatorV3Interface internal priceFeed;

    event FundStarted(address indexed fundOwner, uint256 initialFunds);

    constructor() {
        fundOwner = msg.sender;
        totalFunds = 0;
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    modifier onlyOwner() {
        require(msg.sender == fundOwner, "Not the fund owner");
        _;
    }

    function startFund(uint256 initialFundsAVAX) external onlyOwner {
        uint256 avaxPrice = getPrice();
        totalFunds = PriceConverter.convertAVAXToUSD(initialFundsAVAX, avaxPrice);
        emit FundStarted(fundOwner, totalFunds);
    }

    function getPrice() internal view returns (uint256) {
        return priceFeed.getLatestAvaxPrice();
    }

    function getConversionRate(uint256 avaxAmount) internal view returns (uint256) {
        return avaxAmount.getAvaxToUSDConversionRate(getPrice());
    }

    function getFundBalance() external view returns (uint256) {
        return totalFunds;
    }
}