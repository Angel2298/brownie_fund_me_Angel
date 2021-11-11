// SPDX-Licence-Identifier: MIT

pragma solidity ^0.6.6;

// This is an easiest way to call the contract of AggregatorV3Interface
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// here we are just copy and pasting the interface contract
/*
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
*/

contract FundMe {
    using SafeMathChainlink for uint256;
    
    mapping(address => uint256) public addressToAmountFunded; 
    address[] public funders;
    address public owner; 
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }
    
    function fund() public payable {
        // $50 USD 
        uint256 minimumUSD = 50 * 10 **18; 
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate
        funders.push(msg.sender); 
    
    }
    
    function getVersion() public view returns(uint256){

        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256){
        /** This is equal to say the line below
        (
          uint80 roundId,
          int256 answer,
          uint256 startedAt,
          uint256 updatedAt,
          uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        */
        (,int256 answer,,,) = priceFeed.latestRoundData();        
        return uint256(answer * 10000000000);
         
    }
    
    // 1000000000
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd; 
        // 0.000004567373992380
    }
    
    /*
    //Withdraw function not using the modifier
    function withdraw() payable public {
        //Only want the contract admin/owner
        // require msg.sender = owner
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
    */
    
    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price; 
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable onlyOwner public {
        msg.sender.transfer(address(this).balance);
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; 
        }
        funders = new address[](0); 
    }
    
}