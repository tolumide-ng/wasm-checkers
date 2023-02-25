(module
    (import "events" "piecemoved" (func $notify_piecemoved (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32)))
    (import "events" "piececrowned" (func $notify_piececrowned (param $pieceX i32) (param $pieceY i32)))
    
    (memory $mem 1) ;; the 1 in this memory declaration indicates that the memory named $mem must have at least one 64KB page of memory allocated to it.
    (global $currentTurn (mut i32) (i32.const 0))
    (global $WHITE i32 (i32.const 2))
    (global $BLACK i32 (i32.const 1))
    (global $CROWN i32 (i32.const 4))

    ;; i.e offset = (x + (y * 8)) * 4
    ;; x - x axis
    ;; y - y axis
    ;; 8 - number of colums per row
    ;; 4 - 4 bytes required to store each 32 bits integer (i32)
    (func $indexForPosition (param $x i32) (param $y i32) (result i32)
        ;; x + (y * 8)
        (i32.add
            (i32.mul
                (i32.const 8)
                (local.get $y)
            )
            (local.get $x)
        )
    )
    ;; Get the offset position with indexForPosition function declared earlier
    (func $offsetForPosition (param $x i32) (param $y i32) (result i32)
        (i32.mul 
            (call $indexForPosition (local.get $x) (local.get $y))
            (i32.const 4)
        )
    )

    ;; Determine if a piece has been crowned
    (func $isCrowned (param $piece i32) (result i32)
        (i32.eq
            (i32.and (local.get $piece) (global.get $CROWN))
            (global.get $CROWN)
        )
    )

    ;; Determine if a piece is white
    (func $isWhite(param $piece i32) (result i32)
        (i32.eq
            (i32.and (local.get $piece) (global.get $WHITE))
            (global.get $WHITE)
        )
    )

    ;; Determine if a piece is black
    (func $isBlack (param $piece i32) (result i32)
        (i32.eq
            (i32.and (local.get $piece) (global.get $BLACK))
            (global.get $BLACK)
        )
    )

    ;; Adds a crown to a given piece (no mutation)
    (func $withCrown (param $piece i32) (result i32)
        (i32.or (local.get $piece) (global.get $CROWN))
    )

    ;; Removes a crown from a given piece (no mutation)
    (func $withoutCrown (param $piece i32) (result i32)
        (i32.and (local.get $piece) (i32.const 3))
    )

    ;; Sets a piece on the board
    (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
        (i32.store
            (call $offsetForPosition
                (local.get $x)
                (local.get $y)
            )
            (local.get $piece)
        )
    )

    ;; Detect if values are within range (inclusive high and low)
    (func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
        (i32.and
            (i32.ge_s (local.get  $value) (local.get $low))
            (i32.le_s (local.get $value) (local.get $high))
        )
    )

    ;; Gets a piece from te board. Out of range causes a trap
    (func $getPiece (param $x i32) (param $y i32) (result i32)
        (if (result i32)
            (block (result i32)
                (i32.and
                    (call $inRange
                        (i32.const 0)
                        (i32.const 7)
                        (local.get $x)
                    )
                    (call $inRange
                        (i32.const 0)
                        (i32.const 7)
                        (local.get $y)
                    )
                )
            )
            (then
                (i32.load
                    (call $offsetForPosition
                        (local.get $x)
                        (local.get $y)
                    )
                )
            )
            (else
                (unreachable)
            )
        )
    )

    ;; Gets the current turn owner (white or black)
    (func $getTurnOwner (result i32)
        (global.get $currentTurn)
    )

    ;; Sets the turn owner
    (func $setTurnOwner (param $piece i32)
        (global.set $currentTurn (local.get $piece))
    )

    ;; Toggles the player, after the current player's turn
    (func $toggleTurnOwner
        (if (i32.eq (call $getTurnOwner) (global.get $BLACK))
            (then (call $setTurnOwner (global.get $WHITE)))
            (else (call $setTurnOwner (global.get $BLACK)))
        )
    )

    ;; Determine if it's a player's turn
    (func $isPlayersTurn (param $player i32) (result i32)
        (i32.gt_s
            (i32.and (local.get $player) (call $getTurnOwner))
            (i32.const 0)
        )
    )

    ;; Should this piece get crowned?
    ;; We crown black pieces in row 0, white pieces in row 7
    (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
        (i32.or
            (i32.and
                (i32.eq
                    (local.get $pieceY)
                    (i32.const 0)
                )
                (call $isBlack (local.get $piece))
            )
            
            (i32.and
                (i32.eq
                    (local.get $pieceY)
                    (i32.const 7)
                )
                (call $isWhite (local.get $piece))
            )
        )
    )

    ;; Converts a piece into a crowned piece and invokes a host notifier
    ;; notify_piececrowned: this is provided by the host program. More like a function we call from here to notify the host to crown the piece
    (func $crownPiece (param $x i32) (param $y i32)
        (local $piece i32)
        (local.set $piece (call $getPiece (local.get $x) (local.get $y)))
        (call $setPiece (local.get $x) (local.get $y)
            (call $withCrown (local.get $piece))
        )

        (call $notify_piececrowned (local.get $x)(local.get $y))
    )

    (func $distance (param $x i32)(param $y i32)(result i32)
        (i32.sub (local.get $x)(local.get $y))
    )

    ;; Determine if a move is valid
    (func $isValidMove (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
        (local $player i32)
        (local $target i32)

        (local.set $player (call $getPiece (local.get $fromX) (local.get $fromY)))
        (local.set $target (call $getPiece(local.get $toX) (local.get $toY)))

        (if (result i32)
            (block (result i32)
                (i32.and
                    (call $validJumpDistance (local.get $fromY) (local.get $toY))
                    (i32.and
                        (call $isPlayersTurn (local.get $player))
                        (i32.eq (local.get $target) (i32.const 0)) ;; target has not been occupied before now
                    )
                )
            )
            (then
                (i32.const 1)
            )
            (else
                (i32.const 0)
            )
        )
    )

    ;; Ensures travel is 1 or 2 squares
    (func $validJumpDistance (param $from i32) (param $to i32) (result i32)
        (local $distance i32)
        (local.set $distance
            (if(result i32)
                (i32.gt_s (local.get $to) (local.get $from))
                (then
                    (call $distance (local.get $to) (local.get $from))
                )
                (else
                    (call $distance (local.get $from) (local.get $to))
                )
            )
        )
        (i32.le_u
            (local.get $distance)
            (i32.const 2)
        )
    )

    ;; Move function to be called by the game host, also performs validation of currentPosition and target of the piece
    (func $move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)

        (if (result i32)
            (block (result i32)
                (call $isValidMove (local.get $fromX) (local.get $fromY) (local.get $toX) (local.get $toY))
            )
            (then
                (call $doMove (local.get $fromX) (local.get $fromY) (local.get $toX) (local.get $toY))
            )
            (else 
                (i32.const 0)
            )
        )
    )

    ;; Internal move function, performs actual move post-validation of target
    ;; - Removes opponent piece during a jump
    ;; - Detects win condition
    (func $doMove(param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
        (local $curpiece i32)
        (local.set $curpiece (call $getPiece (local.get $fromX) (local.get $fromY)))

        (call $toggleTurnOwner)
        (call $setPiece (local.get $toX) (local.get $toY) (local.get $curpiece))
        (call $setPiece (local.get $fromX) (local.get $fromY) (i32.const 0))
        (if (call $shouldCrown (local.get $toY) (local.get $curpiece))
            (then (call $crownPiece (local.get $toX) (local.get $toY)))
        )
        (call $notify_piecemoved (local.get $fromX) (local.get $fromY) (local.get $toX) (local.get $toY))
        (i32.const 1)
    )

    ;; Manually place each piece on the board to initialuze the game
    (func $initBoard
        ;; (call $notify_piecemoved (i32.const 0) (i32.const 5) (i32.const 0) (i32.const 4))

        ;; Place the white pieces at the top of the board
        (call $setPiece (i32.const 1) (i32.const 0) (global.get $WHITE))
        (call $setPiece (i32.const 3) (i32.const 0) (global.get $WHITE))
        (call $setPiece (i32.const 5) (i32.const 0) (global.get $WHITE))
        (call $setPiece (i32.const 7) (i32.const 0) (global.get $WHITE))

        (call $setPiece (i32.const 0) (i32.const 1) (global.get $WHITE))
        (call $setPiece (i32.const 2) (i32.const 1) (global.get $WHITE))
        (call $setPiece (i32.const 4) (i32.const 1) (global.get $WHITE))
        (call $setPiece (i32.const 6) (i32.const 1) (global.get $WHITE))

        (call $setPiece (i32.const 1) (i32.const 2) (global.get $WHITE))
        (call $setPiece (i32.const 3) (i32.const 2) (global.get $WHITE))
        (call $setPiece (i32.const 5) (i32.const 2) (global.get $WHITE))
        (call $setPiece (i32.const 7) (i32.const 2) (global.get $WHITE))



        (call $setPiece (i32.const 0) (i32.const 5) (global.get $BLACK))
        (call $setPiece (i32.const 2) (i32.const 5) (global.get $BLACK))
        (call $setPiece (i32.const 4) (i32.const 5) (global.get $BLACK))
        (call $setPiece (i32.const 6) (i32.const 5) (global.get $BLACK))
        
        (call $setPiece (i32.const 1) (i32.const 6) (global.get $BLACK))
        (call $setPiece (i32.const 3) (i32.const 6) (global.get $BLACK))
        (call $setPiece (i32.const 5) (i32.const 6) (global.get $BLACK))
        (call $setPiece (i32.const 7) (i32.const 6) (global.get $BLACK))

        (call $setPiece (i32.const 0) (i32.const 7) (global.get $BLACK))
        (call $setPiece (i32.const 2) (i32.const 7) (global.get $BLACK))
        (call $setPiece (i32.const 4) (i32.const 7) (global.get $BLACK))
        (call $setPiece (i32.const 6) (i32.const 7) (global.get $BLACK))

        ;; Black goes first
        (call $setTurnOwner (global.get $BLACK))
    )

    (export "move" (func $move))
    (export "getPiece" (func $getPiece))
    (export "isCrowned" (func $isCrowned))
    (export "initBoard" (func $initBoard))
    (export "getTurnOwner" (func $getTurnOwner))
    (export "memory" (memory $mem))
)