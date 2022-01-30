pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";


contract Staker {
  event Stake(address, uint256);
  mapping (address => uint256) public balances;
  uint256 public threshold = 2 ether;
  uint256 public deadline = block.timestamp + 180 seconds;
  bool public withdrawAllowance = false;
  bool public executed = false;

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function timeLeft() public view returns(uint256) {
    if (block.timestamp >= deadline) return 0;
    else return (deadline - block.timestamp);
  }

  modifier afterDeadline() {
    require(timeLeft() == 0, "Deadline wasnt reached.");
    _;
  }

  modifier beforeDeadline() {
    require(timeLeft() > 0, "Deadline was reached.");
    _;
  }

  modifier notExecuted() {
    require(!executed, "Already executed.");
    _;
  }

  function stake() public payable beforeDeadline {
    balances[msg.sender] += msg.value;
    if (address(this).balance >= threshold) {
      deadline = block.timestamp;
      exampleExternalContract.complete{value: address(this).balance}();
      executed = true;
    }

    emit Stake(msg.sender, msg.value);
  }

  receive() external payable {
    stake();
  }

  function execute() external afterDeadline notExecuted {
    if (address(this).balance >= threshold)
      exampleExternalContract.complete{value: address(this).balance}();
    else withdrawAllowance = true;
    executed = true;
  }

  function withdraw(address payable) external {
    require(withdrawAllowance, "The withdrawal wasnt allowed.");
    uint256 amount = balances[msg.sender];
    balances[msg.sender] -= amount;
    (bool success, ) = (msg.sender).call{value: amount}("");
    require(success, "Failed to withdraw Ether.");
  }
}

