// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
    constructor(
      string memory _name,
      string memory _symbol,
      uint256 _initSupply
    )
    public
    ERC20(_name, _symbol)
    {
      _mint(msg.sender, _initSupply);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
      _mint(_to, _amount);
    }
}
