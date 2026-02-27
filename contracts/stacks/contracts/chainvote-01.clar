;; ChainVote - Enhanced Decentralized Voting Contract (Clarity v2)
;; Implements weighted voting, delegation, and comprehensive proposal management

;; Constants
(define-constant CONTRACT-OWNER contract-caller)
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-ALREADY-VOTED (err u101))
(define-constant ERR-PROPOSAL-ENDED (err u102))
(define-constant ERR-INVALID-OPTION (err u103))
(define-constant ERR-NOT-ACTIVE (err u104))
(define-constant ERR-UNAUTHORIZED (err u105))
(define-constant ERR-EMPTY-TITLE (err u106))
(define-constant ERR-NO-OPTIONS (err u107))
(define-constant ERR-INVALID-DURATION (err u108))
(define-constant ERR-QUORUM-NOT-REACHED (err u109))
(define-constant ERR-ALREADY-DELEGATED (err u110))

;; Minimum and maximum durations (in blocks)
(define-constant MIN-DURATION u144)  ;; ~24 hours
(define-constant MAX-DURATION u4320) ;; ~30 days

;; Data Variables
(define-data-var proposal-nonce uint u0)
(define-data-var contract-paused bool false)

;; Voting Mechanism Types
;; 0 = Simple (one address = one vote)
;; 1 = Weighted (based on STX balance)
;; 2 = Quadratic (quadratic voting)

;; Data Maps
(define-map proposals
    uint
    {
        creator: principal,
        title: (string-ascii 256),
        description: (string-utf8 1024),
        start-block: uint,
        end-block: uint,
        option-count: uint,
        status: (string-ascii 20),  ;; "active", "ended", "cancelled"
        total-votes: uint,
        mechanism: uint,
        quorum: uint,
        quorum-reached: bool
    }
)

(define-map proposal-options
    {proposal-id: uint, option-index: uint}
    (string-utf8 256)
)

(define-map votes
    {proposal-id: uint, voter: principal}
    {
        option-index: uint,
        weight: uint,
        timestamp: uint
    }
)

(define-map vote-counts
    {proposal-id: uint, option-index: uint}
    uint
)

(define-map delegations
    {proposal-id: uint, delegator: principal}
    {
        delegate: principal,
        timestamp: uint
    }
)

;; Read-only functions

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

(define-read-only (get-delegation (proposal-id uint) (delegator principal))
    (ok (map-get? delegations {proposal-id: proposal-id, delegator: delegator}))
)

(define-read-only (is-paused)
    (ok (var-get contract-paused))
)

(define-read-only (get-winning-option (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
            (option-count (get option-count proposal))
        )
        (ok (fold find-max-votes 
            (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
            {proposal-id: proposal-id, max-votes: u0, winning-option: u0, option-count: option-count}))
    )
)

;; Private functions

(define-private (find-max-votes (option-index uint) (state {proposal-id: uint, max-votes: uint, winning-option: uint, option-count: uint}))
    (let
        (
            (proposal-id (get proposal-id state))
            (max-votes (get max-votes state))
            (winning-option (get winning-option state))
            (option-count (get option-count state))
            (current-votes (default-to u0 (map-get? vote-counts {proposal-id: proposal-id, option-index: option-index})))
        )
        (if (and (< option-index option-count) (> current-votes max-votes))
            {proposal-id: proposal-id, max-votes: current-votes, winning-option: option-index, option-count: option-count}
            state
        )
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

(define-private (calculate-vote-weight (voter principal) (mechanism uint))
    (if (is-eq mechanism u0)
        u1  ;; Simple voting
        (if (is-eq mechanism u1)
            ;; Weighted voting based on STX balance
            (/ (stx-get-balance voter) u1000000)  ;; Weight per 1 STX
            u1  ;; Quadratic (simplified to 1 for now)
        )
    )
)

;; Public functions

(define-public (create-proposal 
    (title (string-ascii 256))
    (description (string-utf8 1024))
    (options (list 10 (string-utf8 256)))
    (duration uint)
    (mechanism uint)
    (quorum uint))
    (let
        (
            (proposal-id (var-get proposal-nonce))
            (end-block (+ block-height duration))
            (option-count (len options))
        )
        ;; Validations
        (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
        (asserts! (> (len title) u0) ERR-EMPTY-TITLE)
        (asserts! (> option-count u0) ERR-NO-OPTIONS)
        (asserts! (and (>= duration MIN-DURATION) (<= duration MAX-DURATION)) ERR-INVALID-DURATION)
        (asserts! (<= mechanism u2) ERR-INVALID-OPTION)
        
        ;; Store proposal
        (map-set proposals proposal-id {
            creator: contract-caller,
            title: title,
            description: description,
            start-block: block-height,
            end-block: end-block,
            option-count: option-count,
            status: "active",
            total-votes: u0,
            mechanism: mechanism,
            quorum: quorum,
            quorum-reached: false
        })
        
        ;; Store options
        (map store-option 
            {proposal-id: proposal-id, options: options}
            (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9))
        
        ;; Increment nonce
        (var-set proposal-nonce (+ proposal-id u1))
        
        (print {
            event: "proposal-created",
            proposal-id: proposal-id,
            creator: contract-caller,
            title: title,
            end-block: end-block
        })
        
        (ok proposal-id)
    )
)

(define-public (cast-vote (proposal-id uint) (option-index uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
            (current-count (default-to u0 (map-get? vote-counts {proposal-id: proposal-id, option-index: option-index})))
            (vote-weight (calculate-vote-weight contract-caller (get mechanism proposal)))
            (new-total-votes (+ (get total-votes proposal) vote-weight))
        )
        ;; Validations
        (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        (asserts! (< block-height (get end-block proposal)) ERR-PROPOSAL-ENDED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: contract-caller})) ERR-ALREADY-VOTED)
        (asserts! (< option-index (get option-count proposal)) ERR-INVALID-OPTION)
        (asserts! (is-none (map-get? delegations {proposal-id: proposal-id, delegator: contract-caller})) ERR-ALREADY-DELEGATED)
        
        ;; Record vote
        (map-set votes {proposal-id: proposal-id, voter: contract-caller} {
            option-index: option-index,
            weight: vote-weight,
            timestamp: block-height
        })
        
        ;; Update vote counts
        (map-set vote-counts {proposal-id: proposal-id, option-index: option-index} (+ current-count vote-weight))
        
        ;; Update proposal
        (map-set proposals proposal-id 
            (merge proposal {
                total-votes: new-total-votes,
                quorum-reached: (if (> (get quorum proposal) u0)
                    (>= new-total-votes (get quorum proposal))
                    (get quorum-reached proposal))
            }))
        
        (print {
            event: "vote-cast",
            proposal-id: proposal-id,
            voter: contract-caller,
            option-index: option-index,
            weight: vote-weight
        })
        
        (ok true)
    )
)

(define-public (delegate-vote (proposal-id uint) (delegate principal))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
        )
        ;; Validations
        (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        (asserts! (< block-height (get end-block proposal)) ERR-PROPOSAL-ENDED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: contract-caller})) ERR-ALREADY-VOTED)
        (asserts! (not (is-eq delegate contract-caller)) ERR-UNAUTHORIZED)
        
        ;; Record delegation
        (map-set delegations {proposal-id: proposal-id, delegator: contract-caller} {
            delegate: delegate,
            timestamp: block-height
        })
        
        (print {
            event: "vote-delegated",
            proposal-id: proposal-id,
            delegator: contract-caller,
            delegate: delegate
        })
        
        (ok true)
    )
)

(define-public (end-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
        )
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        (asserts! (>= block-height (get end-block proposal)) ERR-NOT-ACTIVE)
        
        (map-set proposals proposal-id (merge proposal {status: "ended"}))
        
        (print {
            event: "proposal-ended",
            proposal-id: proposal-id,
            total-votes: (get total-votes proposal)
        })
        
        (ok true)
    )
)

(define-public (cancel-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
        )
        (asserts! (or (is-eq contract-caller (get creator proposal)) (is-eq contract-caller CONTRACT-OWNER)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        
        (map-set proposals proposal-id (merge proposal {status: "cancelled"}))
        
        (print {
            event: "proposal-cancelled",
            proposal-id: proposal-id,
            canceller: contract-caller
        })
        
        (ok true)
    )
)

(define-public (pause-contract)
    (begin
        (asserts! (is-eq contract-caller CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq contract-caller CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set contract-paused false)
        (ok true)
    )
)
