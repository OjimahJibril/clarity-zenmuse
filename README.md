# ZenMuse
A decentralized mindfulness and journaling platform powered by AI on the Stacks blockchain.

## Features
- Create and store private journal entries
- Set mindfulness goals and track progress 
- AI-generated reflection prompts and insights
- Social features for sharing goals and progress
- Token rewards for consistent practice

## Setup and Installation
1. Clone the repository
2. Install Clarinet 
3. Run `clarinet check` to verify contracts
- Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Create a new journal entry
(contract-call? .zenmuse create-entry "My mindful moment today..." u1683900000)

;; Set a mindfulness goal
(contract-call? .zenmuse set-goal "Meditate daily" u30 'DAYS)

;; Get AI reflection prompt
(contract-call? .zenmuse get-prompt)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
