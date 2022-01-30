pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";


contract Staker {

  mapping (address => uint256) public balances;
  uint256 public threshold = 2 ether;
  uint256 public deadline = block.timestamp + 180 seconds;
  bool public withdrawAllowance = false;

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier checkDeadline() {
    require(timeLeft() == 0, "Deadline wasnt reached.");
    _;
  }

  function stake() public payable {

    balances[msg.sender] += msg.value;
  }

  receive() external payable {
    stake();
  }

  function execute() external checkDeadline {
    if (address(this).balance >= threshold)
      exampleExternalContract.complete{value: address(this).balance}();
    else withdrawAllowance = true;
  }

  function withdraw(address payable) external {
    require(withdrawAllowance, "The withdrawal wasnt allowed.");
    uint256 amount = balances[msg.sender];
    balances[msg.sender] -= amount;
    (bool success, ) = (msg.sender).call{value: amount}("");
    require(success, "Failed to withdraw Ether.");
  }

  function timeLeft() public view returns(uint256) {
    if (block.timestamp >= deadline) return 0;
    else return (deadline - block.timestamp);
  }
}

