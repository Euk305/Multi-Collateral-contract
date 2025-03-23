;; Multi-Collateral Stablecoin with BTC Backing
;; A stablecoin system that uses multiple collateral types with Bitcoin as primary backing

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-insufficient-collateral (err u102))
(define-constant err-vault-not-found (err u103))
(define-constant err-vault-undercollateralized (err u104))
(define-constant err-exceeds-debt-ceiling (err u105))
(define-constant err-below-debt-floor (err u106))
(define-constant err-collateral-type-exists (err u107))
(define-constant err-collateral-type-not-found (err u108))
(define-constant err-invalid-parameter (err u109))
(define-constant err-unauthorized-oracle (err u110))
(define-constant err-stablecoin-transfer-failed (err u111))
(define-constant err-insufficient-stablecoin-balance (err u112))
(define-constant err-vault-already-liquidated (err u113))

;; Token definitions
(define-fungible-token stablecoin)