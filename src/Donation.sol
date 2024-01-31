// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Donation {
    uint256 public constant MINIMUM_USD = 1e18;
    address[] private s_donors;
    mapping(address => uint256) private donationBalances;

    function donate() external payable {
        require(getConversionRate(msg.value) >= MINIMUM_USD, "Donation must be $1 or greater");
        donationBalances[msg.sender] += msg.value;
        s_donors.push(msg.sender);
    }

    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
        (, int256 answer, , ,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 avaxAmount) internal view returns (uint256) {
        uint256 avaxPrice = getPrice();
        uint256 avaxAmountInUsd = (avaxAmount * avaxPrice) / 1000000000000000000;
        return avaxAmountInUsd;
    }
}