Escrow-Safe Smart Contract

A Clarity smart contract that provides a **secure escrow mechanism** for conditional payments on the **Stacks blockchain**.  
This contract ensures that funds are only released when predefined conditions are met, enabling trustless transactions between buyers, sellers, and mediators.

---

Overview

The **Escrow-Safe Smart Contract** allows two or more parties to securely hold funds in escrow until specific conditions are satisfied.  
It eliminates the need for intermediaries by using transparent, verifiable logic on the blockchain.

---

Features

- **Secure Fund Escrow:** Lock STX tokens in escrow until both parties agree or a condition is fulfilled.  
- **Conditional Release:** Automatically release funds upon confirmation or dispute resolution.  
- **Refund Option:** Return funds to the sender if the conditions are not met before the deadline.  
- **Transparency:** All transactions and conditions are verifiable on-chain.  
- **Read-Only Access:** Functions to view contract state, escrow status, and balances.  

---

Contract Overview

| Function | Type | Description |
|-----------|------|-------------|
| `create-escrow` | Public | Initializes a new escrow agreement between sender and receiver. |
| `deposit` | Public | Allows the sender to deposit STX tokens into escrow. |
| `release` | Public | Releases escrowed funds to the receiver once conditions are satisfied. |
| `refund` | Public | Returns escrowed funds to the sender if conditions are not met. |
| `get-escrow-details` | Read-only | Retrieves details of an active escrow (participants, amount, and deadline). |
| `get-status` | Read-only | Checks the current status of the escrow (Pending, Released, Refunded). |

---

Example Usage

```clarity
;; Create an escrow agreement
(contract-call? .escrow-safe create-escrow 'SP2C2...ABC 'SP3X9...XYZ u1000 u144)

;; Deposit 1000 STX into escrow
(contract-call? .escrow-safe deposit u1000)

;; Release funds to receiver once condition is met
(contract-call? .escrow-safe release)

;; Refund sender if the deadline expires
(contract-call? .escrow-safe refund)
