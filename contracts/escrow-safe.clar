;; ===============================================================
;; Contract: EscrowSafe.clar
;; Description: A decentralized STX escrow system that holds funds
;;              until both buyer and seller confirm transaction
;;              completion or timeout occurs.
;; ===============================================================

;; ---------------------------
;; Error Codes
;; ---------------------------

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_STATE (err u101))
(define-constant ERR_TRANSFER_FAILED (err u102))
(define-constant ERR_NOT_FOUND (err u103))
(define-constant ERR_TOO_SOON (err u104))

;; ---------------------------
;; Data Structures
;; ---------------------------

(define-map escrows
  uint
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    created-at: uint,
    timeout: uint,
    buyer-approved: bool,
    seller-approved: bool,
    completed: bool
  }
)

(define-data-var escrow-counter uint u0)

;; ---------------------------
;; Private Helper Functions
;; ---------------------------

(define-private (only-participant (escrow-id uint))
  (let ((data (unwrap! (map-get? escrows escrow-id) ERR_NOT_FOUND)))
    (if (or (is-eq tx-sender (get buyer data)) (is-eq tx-sender (get seller data)))
        (ok data)
        ERR_UNAUTHORIZED
    )
  )
)

;; ---------------------------
;; Public Functions
;; ---------------------------

;; Create an escrow agreement
(define-public (create-escrow (seller principal) (amount uint) (timeout uint))
  (begin
    (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) ERR_TRANSFER_FAILED)
    (let ((id (+ (var-get escrow-counter) u1)))
      (map-set escrows
        id
        {
          buyer: tx-sender,
          seller: seller,
          amount: amount,
          created-at: stacks-block-height,
          timeout: timeout,
          buyer-approved: false,
          seller-approved: false,
          completed: false
        }
      )
      (var-set escrow-counter id)
      ;; Removed to-utf8 function call and replaced with simple success message
      (ok "Escrow created successfully.")
    )
  )
)

;; Buyer or seller confirms transaction completion
(define-public (approve-escrow (escrow-id uint))
  (let ((data (unwrap! (only-participant escrow-id) ERR_UNAUTHORIZED)))
    (if (get completed data)
        ERR_INVALID_STATE
        (let (
              (buyer (get buyer data))
              (seller (get seller data))
             )
          (if (is-eq tx-sender buyer)
              (map-set escrows escrow-id (merge data {buyer-approved: true}))
              (map-set escrows escrow-id (merge data {seller-approved: true}))
          )
          (ok "Approval recorded.")
        )
    )
  )
)

;; Finalize escrow when both parties approve
(define-public (finalize-escrow (escrow-id uint))
  (let ((data (unwrap! (map-get? escrows escrow-id) ERR_NOT_FOUND)))
    (if (and (get buyer-approved data) (get seller-approved data) (not (get completed data)))
        (begin
          (unwrap! (stx-transfer? (get amount data) (as-contract tx-sender) (get seller data)) ERR_TRANSFER_FAILED)
          (map-set escrows escrow-id (merge data {completed: true}))
          (ok "Escrow completed successfully.")
        )
        ERR_INVALID_STATE
    )
  )
)

;; Refund buyer after timeout if not completed
(define-public (refund (escrow-id uint))
  (let ((data (unwrap! (map-get? escrows escrow-id) ERR_NOT_FOUND)))
    (if (>= stacks-block-height (+ (get created-at data) (get timeout data)))
        (if (not (get completed data))
            (begin
              (unwrap! (stx-transfer? (get amount data) (as-contract tx-sender) (get buyer data)) ERR_TRANSFER_FAILED)
              (map-set escrows escrow-id (merge data {completed: true}))
              (ok "Escrow refunded to buyer after timeout.")
            )
            ERR_INVALID_STATE
        )
        ERR_TOO_SOON
    )
  )
)

;; ---------------------------
;; Read-Only Functions
;; ---------------------------

(define-read-only (get-escrow (escrow-id uint))
  (ok (map-get? escrows escrow-id))
)

(define-read-only (get-total-escrows)
  (ok (var-get escrow-counter))
)
