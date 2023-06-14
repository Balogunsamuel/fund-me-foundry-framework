// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

//Get funds from users
//Withdraw funds
//Set a mimimum funding value in USD

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_VALUE_USD = 5e18;

    address[] public s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_funderToTheAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender not the owner);
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function fund() public payable {
        //Allow the user to send a minimum of $5 to this contract
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_VALUE_USD,
            "didnt send enough Eth"
        );
        s_funders.push(msg.sender);
        s_funderToTheAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_funderToTheAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //run this code
            address funder = s_funders[funderIndex];
            s_funderToTheAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);
        //ways of withrawing the funds

        // //transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sucSucess = payable(msg.sender).send(address(this).balance);
        // require(sucSucess, "SendFailed");
        //call
        (bool sucesss, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sucesss, "Call failed");
    }

    // one of this functions will excute even if the  fund function is not call, but transcation sent to the contract directly

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // Views and Pure functions

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_funderToTheAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
