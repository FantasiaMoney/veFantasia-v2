pragma solidity ^0.6.2;

import "./interfaces/IMint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Minter is Ownable {
  address public token;
  mapping (address => bool) public permitted;

  constructor(address _token) public {
    token = _token;
  }

  function updatePermittion(address _to, bool _status)
    external
    onlyOwner
  {
    permitted[_to] = _status;
  }

  function mint(address _to, uint256 _amount) external {
    require(permitted[msg.sender], "Not permitted");
    IMint(address).mint(_to, _amount);
  }
}
