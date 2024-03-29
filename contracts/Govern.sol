// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

contract Govern is ERC20 {
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    mapping(address => bool) hasVoted;

    struct Proposal {
        uint yesCount;
        uint noCount;
        mapping(address => bool) hasVoted;
    }
    
    uint numProposals;
    mapping(uint => Proposal) public proposals;

    constructor() ERC20("Govern", "GOV") {}
    
    function buy(uint _amount) external {
        DAI.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function sell(uint _amount) external {
        _burn(msg.sender, _amount);
        DAI.transfer(msg.sender, _amount);
    }

    function vote(uint _proposalId, bool _supports) external {
        require(!hasVoted[msg.sender]);
        Proposal storage proposal = proposals[_proposalId];

        if(_supports) {
            proposal.yesCount += balanceOf(msg.sender);
        } else {
            proposal.noCount += balanceOf(msg.sender);
        }

        proposal.hasVoted[msg.sender] = _supports;
    }
}