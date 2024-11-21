-- Board.lua
local Board = {}

function Board:new()
    local newObj = {}
    self.__index = self
    setmetatable(newObj, self)
    newObj:init()
    return newObj
end

function Board:init()
    self.boardSize = 8
    self.pieces = {}
    for row = 1, self.boardSize do
        self.pieces[row] = {}
        for col = 1, self.boardSize do
            self.pieces[row][col] = nil
        end
    end

    -- Place black pieces
    self.pieces[1][1] = {name = "black_rook", moved = false}
    self.pieces[1][2] = {name = "black_knight"}
    self.pieces[1][3] = {name = "black_bishop"}
    self.pieces[1][4] = {name = "black_queen"}
    self.pieces[1][5] = {name = "black_king", moved = false}
    self.pieces[1][6] = {name = "black_bishop"}
    self.pieces[1][7] = {name = "black_knight"}
    self.pieces[1][8] = {name = "black_rook", moved = false}
    for col = 1, self.boardSize do
        self.pieces[2][col] = {name = "black_pawn", movedTwoSquaresLastMove = false}
    end

    -- Place white pieces
    self.pieces[8][1] = {name = "white_rook", moved = false}
    self.pieces[8][2] = {name = "white_knight"}
    self.pieces[8][3] = {name = "white_bishop"}
    self.pieces[8][4] = {name = "white_queen"}
    self.pieces[8][5] = {name = "white_king", moved = false}
    self.pieces[8][6] = {name = "white_bishop"}
    self.pieces[8][7] = {name = "white_knight"}
    self.pieces[8][8] = {name = "white_rook", moved = false}
    for col = 1, self.boardSize do
        self.pieces[7][col] = {name = "white_pawn", movedTwoSquaresLastMove = false}
    end

    self.currentTurn = "white"

    -- Keep track of last move for en passant
    self.lastMove = nil
end

function Board:getPiece(row, col)
    if row >= 1 and row <= self.boardSize and col >= 1 and col <= self.boardSize then
        return self.pieces[row][col]
    else
        return nil
    end
end

function Board:setPiece(row, col, piece)
    if row >= 1 and row <= self.boardSize and col >= 1 and col <= self.boardSize then
        self.pieces[row][col] = piece
    end
end

function Board:movePiece(fromRow, fromCol, toRow, toCol)
    local piece = self:getPiece(fromRow, fromCol)
    if piece and piece.name:find(self.currentTurn) and self:isLegalMove(fromRow, fromCol, toRow, toCol) then
        -- Handle special cases before making the move
        local targetPiece = self:getPiece(toRow, toCol)

        -- En passant capture
        if piece.name:find("pawn") and toCol ~= fromCol and not targetPiece then
            local direction = piece.name:find("white") and -1 or 1
            self:setPiece(toRow - direction, toCol, nil) -- Remove the captured pawn
        end

        -- Castling
        if piece.name:find("king") and math.abs(toCol - fromCol) == 2 then
            if toCol > fromCol then
                -- Kingside castling
                local rook = self:getPiece(fromRow, self.boardSize)
                self:setPiece(fromRow, self.boardSize, nil)
                self:setPiece(toRow, toCol - 1, rook)
                rook.moved = true
            else
                -- Queenside castling
                local rook = self:getPiece(fromRow, 1)
                self:setPiece(fromRow, 1, nil)
                self:setPiece(toRow, toCol + 1, rook)
                rook.moved = true
            end
        end

        -- Move the piece
        self:setPiece(toRow, toCol, piece)
        self:setPiece(fromRow, fromCol, nil)

        -- Mark piece as moved (for pawns, kings, and rooks)
        if piece.name:find("pawn") then
            -- Check if pawn moved two squares
            piece.movedTwoSquaresLastMove = math.abs(toRow - fromRow) == 2
        else
            piece.movedTwoSquaresLastMove = false
        end

        if piece.name:find("king") or piece.name:find("rook") or piece.name:find("pawn") then
            piece.moved = true
        end

        -- Promotion (assuming promotion to queen)
        if piece.name:find("pawn") then
            if (piece.name:find("white") and toRow == 1) or (piece.name:find("black") and toRow == 8) then
                piece.name = piece.name:gsub("pawn", "queen")
            end
        end

        -- Update last move
        self.lastMove = {
            piece = piece,
            fromRow = fromRow,
            fromCol = fromCol,
            toRow = toRow,
            toCol = toCol
        }

        -- Change turn
        self.currentTurn = self.currentTurn == "white" and "black" or "white"
        return true
    else
        return false
    end
end

function Board:getLegalMoves(row, col)
    local piece = self:getPiece(row, col)
    local moves = {}
    if piece and piece.name:find(self.currentTurn) then
        local pieceType = piece.name:match("_(.+)")
        if pieceType == "pawn" then
            moves = self:getPawnMoves(row, col, piece)
        elseif pieceType == "knight" then
            moves = self:getKnightMoves(row, col, piece)
        elseif pieceType == "bishop" then
            moves = self:getBishopMoves(row, col, piece)
        elseif pieceType == "rook" then
            moves = self:getRookMoves(row, col, piece)
        elseif pieceType == "queen" then
            moves = self:getQueenMoves(row, col, piece)
        elseif pieceType == "king" then
            moves = self:getKingMoves(row, col, piece)
        end

        -- Filter out moves that leave king in check
        local legalMoves = {}
        for _, move in ipairs(moves) do
            if not self:leavesKingInCheck(row, col, move.row, move.col) then
                table.insert(legalMoves, move)
            end
        end
        moves = legalMoves
    end
    return moves
end

function Board:isLegalMove(fromRow, fromCol, toRow, toCol)
    local legalMoves = self:getLegalMoves(fromRow, fromCol)
    for _, move in ipairs(legalMoves) do
        if move.row == toRow and move.col == toCol then
            return true
        end
    end
    return false
end

-- Pawn movement logic
function Board:getPawnMoves(row, col, piece)
    local moves = {}
    local direction = piece.name:find("white") and -1 or 1
    local startRow = piece.name:find("white") and 7 or 2
    local enemyColor = piece.name:find("white") and "black" or "white"

    -- Move forward
    local nextRow = row + direction
    if self:getPiece(nextRow, col) == nil then
        table.insert(moves, {row = nextRow, col = col})
        -- Move two squares from starting position
        if row == startRow and self:getPiece(row + 2 * direction, col) == nil then
            table.insert(moves, {row = row + 2 * direction, col = col})
        end
    end

    -- Captures
    for _, dc in ipairs({-1, 1}) do
        local captureCol = col + dc
        local targetPiece = self:getPiece(nextRow, captureCol)
        if targetPiece and targetPiece.name:find(enemyColor) then
            table.insert(moves, {row = nextRow, col = captureCol})
        end
    end

    -- En passant
    if self.lastMove and self.lastMove.piece.name:find(enemyColor .. "_pawn") then
        if math.abs(self.lastMove.toRow - self.lastMove.fromRow) == 2 then
            if self.lastMove.toRow == row and math.abs(self.lastMove.toCol - col) == 1 then
                table.insert(moves, {row = row + direction, col = self.lastMove.toCol})
            end
        end
    end

    return moves
end

-- Knight movement logic
function Board:getKnightMoves(row, col, piece)
    local moves = {}
    local enemyColor = piece.name:find("white") and "black" or "white"
    local potentialMoves = {
        {row + 2, col + 1}, {row + 2, col -1},
        {row - 2, col + 1}, {row - 2, col -1},
        {row + 1, col + 2}, {row + 1, col -2},
        {row - 1, col + 2}, {row - 1, col -2}
    }

    for _, pos in ipairs(potentialMoves) do
        local r, c = pos[1], pos[2]
        local targetPiece = self:getPiece(r, c)
        if r >=1 and r <= self.boardSize and c >=1 and c <= self.boardSize then
            if not targetPiece or targetPiece.name:find(enemyColor) then
                table.insert(moves, {row = r, col = c})
            end
        end
    end

    return moves
end

-- Bishop movement logic
function Board:getBishopMoves(row, col, piece)
    local moves = {}
    local enemyColor = piece.name:find("white") and "black" or "white"
    local directions = {{1,1}, {1,-1}, {-1,1}, {-1,-1}}
    for _, dir in ipairs(directions) do
        local r, c = row, col
        while true do
            r = r + dir[1]
            c = c + dir[2]
            if r < 1 or r > self.boardSize or c < 1 or c > self.boardSize then
                break
            end
            local targetPiece = self:getPiece(r, c)
            if targetPiece == nil then
                table.insert(moves, {row = r, col = c})
            elseif targetPiece.name:find(enemyColor) then
                table.insert(moves, {row = r, col = c})
                break
            else
                break
            end
        end
    end
    return moves
end

-- Rook movement logic
function Board:getRookMoves(row, col, piece)
    local moves = {}
    local enemyColor = piece.name:find("white") and "black" or "white"
    local directions = {{1,0}, {-1,0}, {0,1}, {0,-1}}
    for _, dir in ipairs(directions) do
        local r, c = row, col
        while true do
            r = r + dir[1]
            c = c + dir[2]
            if r < 1 or r > self.boardSize or c < 1 or c > self.boardSize then
                break
            end
            local targetPiece = self:getPiece(r, c)
            if targetPiece == nil then
                table.insert(moves, {row = r, col = c})
            elseif targetPiece.name:find(enemyColor) then
                table.insert(moves, {row = r, col = c})
                break
            else
                break
            end
        end
    end
    return moves
end

-- Queen movement logic
function Board:getQueenMoves(row, col, piece)
    local moves = self:getBishopMoves(row, col, piece)
    local rookMoves = self:getRookMoves(row, col, piece)
    for _, move in ipairs(rookMoves) do
        table.insert(moves, move)
    end
    return moves
end

-- King movement logic
function Board:getKingMoves(row, col, piece, ignoreKingSafety)
    local moves = {}
    local enemyColor = piece.name:find("white") and "black" or "white"
    for dr = -1,1 do
        for dc = -1,1 do
            if dr ~= 0 or dc ~= 0 then
                local r = row + dr
                local c = col + dc
                if r >=1 and r <= self.boardSize and c >=1 and c <= self.boardSize then
                    local targetPiece = self:getPiece(r, c)
                    if not targetPiece or targetPiece.name:find(enemyColor) then
                        if ignoreKingSafety then
                            table.insert(moves, {row = r, col = c})
                        else
                            -- Check if moving to (r, c) puts king in check
                            if not self:squareUnderAttack(r, c, enemyColor) then
                                table.insert(moves, {row = r, col = c})
                            end
                        end
                    end
                end
            end
        end
    end

    if not ignoreKingSafety then
        -- Castling
        if not piece.moved then
            -- Kingside castling
            if self:canCastle(row, col, "kingside") then
                table.insert(moves, {row = row, col = col + 2})
            end
            -- Queenside castling
            if self:canCastle(row, col, "queenside") then
                table.insert(moves, {row = row, col = col - 2})
            end
        end
    end

    return moves
end

function Board:canCastle(row, col, side)
    local piece = self:getPiece(row, col)
    if not piece or piece.moved then
        return false
    end
    local enemyColor = piece.name:find("white") and "black" or "white"
    local rookCol = side == "kingside" and self.boardSize or 1
    local rook = self:getPiece(row, rookCol)
    if not rook or rook.moved or not rook.name:find("rook") or not rook.name:find(self.currentTurn) then
        return false
    end

    local step = side == "kingside" and 1 or -1
    local startCol = col + step
    local endCol = side == "kingside" and col + 2 or col -2

    for c = startCol, endCol, step do
        if self:getPiece(row, c) ~= nil then
            return false
        end
        if self:squareUnderAttack(row, c, enemyColor) then
            return false
        end
    end

    -- Also check if king is currently in check
    if self:squareUnderAttack(row, col, enemyColor) then
        return false
    end

    return true
end

function Board:leavesKingInCheck(fromRow, fromCol, toRow, toCol)
    -- Simulate the move
    local piece = self:getPiece(fromRow, fromCol)
    local capturedPiece = self:getPiece(toRow, toCol)
    self:setPiece(toRow, toCol, piece)
    self:setPiece(fromRow, fromCol, nil)

    local inCheck = self:isKingInCheck(self.currentTurn)

    -- Undo the move
    self:setPiece(fromRow, fromCol, piece)
    self:setPiece(toRow, toCol, capturedPiece)

    return inCheck
end

function Board:isKingInCheck(color)
    local kingRow, kingCol = self:findKing(color)
    if kingRow and kingCol then
        return self:squareUnderAttack(kingRow, kingCol, color == "white" and "black" or "white")
    else
        return true -- King not found, consider in check
    end
end

function Board:findKing(color)
    for row = 1, self.boardSize do
        for col = 1, self.boardSize do
            local piece = self:getPiece(row, col)
            if piece and piece.name == color .. "_king" then
                return row, col
            end
        end
    end
    return nil, nil
end

function Board:squareUnderAttack(row, col, attackerColor)
    -- Check all enemy pieces to see if they can move to (row, col)
    for r = 1, self.boardSize do
        for c = 1, self.boardSize do
            local piece = self:getPiece(r, c)
            if piece and piece.name:find(attackerColor) then
                if piece.name:find("king") then
                    -- For the enemy king, consider adjacent squares
                    if math.abs(r - row) <= 1 and math.abs(c - col) <=1 and (r ~= row or c ~= col) then
                        return true
                    end
                else
                    local moves = self:getPotentialMoves(r, c, piece, true)
                    for _, move in ipairs(moves) do
                        if move.row == row and move.col == col then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function Board:getPotentialMoves(row, col, piece, ignoreKingSafety)
    -- Similar to getLegalMoves but doesn't check for leaving king in check
    local moves = {}
    local pieceType = piece.name:match("_(.+)")
    if pieceType == "pawn" then
        moves = self:getPawnMoves(row, col, piece)
    elseif pieceType == "knight" then
        moves = self:getKnightMoves(row, col, piece)
    elseif pieceType == "bishop" then
        moves = self:getBishopMoves(row, col, piece)
    elseif pieceType == "rook" then
        moves = self:getRookMoves(row, col, piece)
    elseif pieceType == "queen" then
        moves = self:getQueenMoves(row, col, piece)
    elseif pieceType == "king" then
        moves = self:getKingMoves(row, col, piece, ignoreKingSafety)
    end
    return moves
end

return Board
