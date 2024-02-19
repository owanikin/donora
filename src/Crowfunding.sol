// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract Crowdfunding {
    using PriceConverter for uint256;

    address public platform; // Address of the platform deploying the contract
    uint256 public totalFunds;
    uint256 public platformCommission; // Percentage of funds taken as a commission
    uint256 public matchingRatio; // Matching ratio for corporate sponsors

    AggregatorV3Interface internal priceFeed;

    event FundStarted(address indexed fundOwner, uint256 targetAmount, uint256 initialFunds);
    event DonationReceived(address indexed donor, uint256 amount, uint256 matchingAmount);
    event FundClosed(address indexed fundOwner, uint256 totalAmountRaised, uint256 platformCommission);

    struct Fund {
        address fundOwner;
        uint256 targetAmount;
        uint256 amountRaised;
        bool active;
        uint256 matchingPool; // Total matching funds from corporate sponsors
        string purpose;
    }

    mapping(address => Fund) public funds;

    modifier onlyPlatform() {
        require(msg.sender == platform, "Not the platform");
        _;
    }

    modifier onlyFundOwner(address _fundOwner) {
        require(msg.sender == _fundOwner, "Not the fund owner");
        _;
    }

    constructor() {
        platform = msg.sender; // Set the deployer as the platform
        totalFunds = 0;
        platformCommission = 5; // 5% platform commission (adjust as needed)
        matchingRatio = 2; // 2:1 matching ratio (2 ether from sponsor for every 1 ether donated)
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    function startFund(string memory _purpose, uint256 targetAmount) external {
        require(!funds[msg.sender].active, "Fund already active");

        funds[msg.sender] = Fund({
            fundOwner: msg.sender,
            targetAmount: targetAmount,
            amountRaised: 0,
            active: true,
            matchingPool: 0,
            purpose: _purpose
        });

        emit FundStarted(msg.sender, targetAmount, 0);
    }

    function contribute(address fundOwner) external payable {
        Fund storage fund = funds[fundOwner];
        require(fund.active, "Fund not active");
        require(msg.value > 0, "Contribution amount must be greater than 0");

        uint256 matchingAmount = (msg.value * matchingRatio) / 1 ether;
        uint256 commissionAmount = (msg.value * platformCommission) / 100;
        uint256 remainingContribution = msg.value - commissionAmount;

        fund.amountRaised += remainingContribution;

        payable(platform).transfer(commissionAmount);

        require(fund.matchingPool >= matchingAmount, "Insufficient matching funds");
        fund.matchingPool -= matchingAmount;

        emit DonationReceived(msg.sender, remainingContribution, matchingAmount);

        if (fund.amountRaised >= fund.targetAmount) {
            fund.active = false;
            totalFunds += fund.amountRaised;
            emit FundClosed(fundOwner, fund.amountRaised, commissionAmount);
        }
    }

    function pledgeMatchingFunds(address fundOwner, uint256 matchingAmount) external payable {
        Fund storage fund = funds[fundOwner];
        require(fund.active, "Fund not active");
        require(matchingAmount > 0, "Matching amount must be greater than 0");

        fund.matchingPool += matchingAmount;

        require(msg.value == matchingAmount, "Incorrect matching amount sent");
        emit DonationReceived(msg.sender, 0, matchingAmount);
    }

    function getConversionRate(uint256 avaxAmount) external view returns (uint256) {
        // return avaxAmount.getAvaxToUSDConversionRate(getPrice());
        return avaxAmount * getPrice();
    }

    function getPrice() internal view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price);
    }
}