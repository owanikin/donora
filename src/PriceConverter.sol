// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getLatestAvaxPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    } 

    function convertAVAXToUSD(uint256 avaxAmount, uint256 avaxPrice) internal pure returns (uint256) {
        // Convert the AVAX to amount to USD
        require(avaxPrice > 0, "Invalid AVAX price");
        return (avaxAmount * 1e18) / avaxPrice;
    }

    function convertUSDToAvax(uint256 usdAmount, uint256 avaxPrice) internal pure returns (uint256) {
        require(avaxPrice > 0, "Invalid AVAX price");
        // Convert the USD amount to AVAX
        return (usdAmount * 1e18) / avaxPrice; 
    }
}