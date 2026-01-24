;; ChainVote - Decentralized Voting Contract (Clarity v4)
;; Allows users to create proposals and vote on them

;; Data Variables
(define-data-var proposal-nonce uint u0)

;; Data Maps
(define-map proposals
    uint
    {
        creator: principal,
        title: (string-ascii 256),
        description: (string-utf8 1024),
        end-block: uint,
        option-count: uint,
        active: bool,
        total-votes: uint
    }
)

(define-map proposal-options
    {proposal-id: uint, option-index: uint}
    (string-utf8 256)
)

(define-map votes
    {proposal-id: uint, voter: principal}
    uint
)

(define-map vote-counts
    {proposal-id: uint, option-index: uint}
    uint
)

;; Error Codes
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-ALREADY-VOTED (err u101))
(define-constant ERR-PROPOSAL-ENDED (err u102))
(define-constant ERR-INVALID-OPTION (err u103))
(define-constant ERR-NOT-ACTIVE (err u104))
(define-constant ERR-UNAUTHORIZED (err u105))
(define-constant ERR-EMPTY-TITLE (err u106))
(define-constant ERR-NO-OPTIONS (err u107))

;; Public Functions

(define-public (create-proposal 
    (title (string-ascii 256))
    (description (string-utf8 1024))
    (options (list 10 (string-utf8 256)))
    (duration uint))
    (let
        (
            (proposal-id (var-get proposal-nonce))
            (end-block (+ block-height duration))
            (option-count (len options))
        )
        (asserts! (> (len title) u0) ERR-EMPTY-TITLE)
        (asserts! (> option-count u0) ERR-NO-OPTIONS)
        
        ;; Store proposal
        (map-set proposals proposal-id {
            creator: tx-sender,
            title: title,
            description: description,
            end-block: end-block,
            option-count: option-count,
            active: true,
            total-votes: u0
        })
        
        ;; Store options
        (map store-option 
            {proposal-id: proposal-id, options: options}
            (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9))
        
        ;; Increment nonce
        (var-set proposal-nonce (+ proposal-id u1))
        
        (ok proposal-id)
    )
)

(define-private (store-option (data {proposal-id: uint, options: (list 10 (string-utf8 256))}) (index uint))
    (match (element-at (get options data) index)
        option (map-set proposal-options 
                   {proposal-id: (get proposal-id data), option-index: index}
                   option)
        false
    )
)

(define-public (cast-vote (proposal-id uint) (option-index uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
            (current-count (default-to u0 (map-get? vote-counts {proposal-id: proposal-id, option-index: option-index})))
        )
        ;; Validations
        (asserts! (get active proposal) ERR-NOT-ACTIVE)
        (asserts! (< block-height (get end-block proposal)) ERR-PROPOSAL-ENDED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
        (asserts! (< option-index (get option-count proposal)) ERR-INVALID-OPTION)
        
        ;; Record vote
        (map-set votes {proposal-id: proposal-id, voter: tx-sender} option-index)
        (map-set vote-counts {proposal-id: proposal-id, option-index: option-index} (+ current-count u1))
        
        ;; Update total votes
        (map-set proposals proposal-id 
            (merge proposal {total-votes: (+ (get total-votes proposal) u1)}))
        
        (ok true)
    )
)

(define-public (end-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get creator proposal)) ERR-UNAUTHORIZED)
        (asserts! (get active proposal) ERR-NOT-ACTIVE)
        
        (map-set proposals proposal-id (merge proposal {active: false}))
        (ok true)
    )
)

;; Read-Only Functions

(define-read-only (get-proposal (proposal-id uint))
    (ok (map-get? proposals proposal-id))
)

(define-read-only (get-option (proposal-id uint) (option-index uint))
    (ok (map-get? proposal-options {proposal-id: proposal-id, option-index: option-index}))
)

(define-read-only (get-vote-count (proposal-id uint) (option-index uint))
    (ok (default-to u0 (map-get? vote-counts {proposal-id: proposal-id, option-index: option-index})))
)

(define-read-only (get-user-vote (proposal-id uint) (voter principal))
    (ok (map-get? votes {proposal-id: proposal-id, voter: voter}))
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
    (ok (is-some (map-get? votes {proposal-id: proposal-id, voter: voter})))
)

(define-read-only (get-proposal-count)
    (ok (var-get proposal-nonce))
)
