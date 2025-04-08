;; Property Verification Contract
;; This contract validates the legal status and condition of a property

(define-data-var admin principal tx-sender)

;; Property status enum
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_REJECTED u2)

;; Property struct
(define-map properties
  { property-id: (string-ascii 36) }
  {
    owner: principal,
    address: (string-ascii 100),
    value: uint,
    status: uint,
    verification-date: uint,
    verified-by: principal
  }
)

;; Register a new property
(define-public (register-property
    (property-id (string-ascii 36))
    (address (string-ascii 100))
    (value uint))
  (let
    ((caller tx-sender))
    (if (map-insert properties
          { property-id: property-id }
          {
            owner: caller,
            address: address,
            value: value,
            status: STATUS_PENDING,
            verification-date: u0,
            verified-by: caller
          })
        (ok true)
        (err u1))))

;; Verify a property
(define-public (verify-property
    (property-id (string-ascii 36)))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
      (match (map-get? properties { property-id: property-id })
        property
        (begin
          (map-set properties
            { property-id: property-id }
            (merge property {
              status: STATUS_VERIFIED,
              verification-date: block-height,
              verified-by: caller
            }))
          (ok true))
        (err u2))
      (err u3))))

;; Reject a property
(define-public (reject-property
    (property-id (string-ascii 36)))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
      (match (map-get? properties { property-id: property-id })
        property
        (begin
          (map-set properties
            { property-id: property-id }
            (merge property {
              status: STATUS_REJECTED,
              verification-date: block-height,
              verified-by: caller
            }))
          (ok true))
        (err u2))
      (err u3))))

;; Get property details
(define-read-only (get-property (property-id (string-ascii 36)))
  (map-get? properties { property-id: property-id }))

;; Check if property is verified
(define-read-only (is-property-verified (property-id (string-ascii 36)))
  (match (map-get? properties { property-id: property-id })
    property (is-eq (get status property) STATUS_VERIFIED)
    false))

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
      (begin
        (var-set admin new-admin)
        (ok true))
      (err u4))))
