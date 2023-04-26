// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;
/// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
	    struct Voter {
	        uint delegateWeight; // weight is accumulated by delegation
		    bool isAbleToVote; // if true, that person have the right to vote/delegate
	        bool voted;  // if true, that person already voted
	        address delegate; // person delegated to
	        uint vote;   // index of the voted proposal
	    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;
    bytes32[] winningProposals;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames) {
        // ARGUMENT TO TET THE DEPLOY ["0x1000000000000000000000000000000000000000000000000000000000000000", "0x2000000000000000000000000000000000000000000000000000000000000000"]
        chairperson = msg.sender;
        voters[chairperson].isAbleToVote = true;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function getVoteRights() external {
        require(msg.sender != chairperson, "You are Chirperson, you already have rights to vote");
        // require that msg.sender dind't vote, otherwise revert the transaction
        require(!voters[msg.sender].voted, "You have already voted");
        require(!voters[msg.sender].isAbleToVote, "You already got rights vote");

        voters[msg.sender].isAbleToVote = true;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) external {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(sender.isAbleToVote, "You have no right to vote");
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];

        // Voters cannot delegate to accounts that cannot vote.
        require(delegate_.isAbleToVote, "You choose a delegate that can't vote");

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender]`.
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += calcSenderVotingWeight() ;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.delegateWeight += calcSenderVotingWeight();
        }
    }

    function calcSenderVotingWeight() view internal returns(uint totWeight)  {
        totWeight = 0;
		uint rightToVote = 0;
		if (voters[msg.sender].isAbleToVote) rightToVote=1;
		totWeight = (voters[msg.sender].delegateWeight + 1) * rightToVote;
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.isAbleToVote, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += calcSenderVotingWeight();
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function getWinningProposal() public {
        // TODO add event to print winning proposals
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount >= winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
            }
        }
        for(uint p=0; p<proposals.length; p++){
            if (proposals[p].voteCount == winningVoteCount) {
                winningProposals.push(proposals[p].name);
            }
        }
    }

}
