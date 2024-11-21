-- main.lua
function love.load()
    -- Set up the window
    love.window.setTitle("Simple Chess Game")
    windowWidth = love.graphics.getWidth()
    windowHeight = love.graphics.getHeight()

    -- Load the piece images
    pieceImages = {
        ["white_pawn"] = love.graphics.newImage('assets/white_pawn.png'),
        ["white_rook"] = love.graphics.newImage('assets/white_rook.png'),
        ["white_knight"] = love.graphics.newImage('assets/white_knight.png'),
        ["white_bishop"] = love.graphics.newImage('assets/white_bishop.png'),
        ["white_queen"] = love.graphics.newImage('assets/white_queen.png'),
        ["white_king"] = love.graphics.newImage('assets/white_king.png'),
        ["black_pawn"] = love.graphics.newImage('assets/black_pawn.png'),
        ["black_rook"] = love.graphics.newImage('assets/black_rook.png'),
        ["black_knight"] = love.graphics.newImage('assets/black_knight.png'),
        ["black_bishop"] = love.graphics.newImage('assets/black_bishop.png'),
        ["black_queen"] = love.graphics.newImage('assets/black_queen.png'),
        ["black_king"] = love.graphics.newImage('assets/black_king.png'),
    }

    -- Define the board
    boardSize = 8
    squareSize = math.min(windowWidth, windowHeight) * 0.8 / boardSize
    boardStartX = (windowWidth - (squareSize * boardSize)) / 2
    boardStartY = (windowHeight - (squareSize * boardSize)) / 2

    -- Compute scale factor for pieces
    local pieceOriginalWidth = pieceImages["white_pawn"]:getWidth()
    scaleFactor = (squareSize) / pieceOriginalWidth

    -- Initialize the Board
    Board = require 'Board'
    gameBoard = Board:new()

    -- Flipping variable
    isFlipped = false

    -- Flip button
    flipButton = {
        x = windowWidth / 2 - 40,
        y = 20,
        width = 80,
        height = 30,
        text = "Flip Board"
    }

    -- Files and Ranks for coordinates
    files = {"a", "b", "c", "d", "e", "f", "g", "h"}

    -- Initialize dragging variables
    selectedPiece = nil
    mouseOffsetX = 0
    mouseOffsetY = 0

    -- Legal moves for the selected piece
    possibleMoves = {}
end

function love.resize(w, h)
    windowWidth = w
    windowHeight = h
    squareSize = math.min(windowWidth, windowHeight) * 0.8 / boardSize
    boardStartX = (windowWidth - (squareSize * boardSize)) / 2
    boardStartY = (windowHeight - (squareSize * boardSize)) / 2
    flipButton.x = windowWidth / 2 - flipButton.width / 2
    -- Recompute scaleFactor
    local pieceOriginalWidth = pieceImages["white_pawn"]:getWidth()
    scaleFactor = (squareSize) / pieceOriginalWidth
end

function love.update(dt)
    -- Update the position of the selected piece if dragging
    if selectedPiece and love.mouse.isDown(1) then
        local mouseX, mouseY = love.mouse.getPosition()
        selectedPiece.drawX = mouseX + mouseOffsetX
        selectedPiece.drawY = mouseY + mouseOffsetY
    end

    -- Check for window resize (for love.js if love.resize isn't automatically called)
    local currentWidth = love.graphics.getWidth()
    local currentHeight = love.graphics.getHeight()
    if currentWidth ~= windowWidth or currentHeight ~= windowHeight then
        love.resize(currentWidth, currentHeight)
    end
end

function love.draw()
    -- Draw the panel background
    love.graphics.setColor(0.95, 0.89, 0.78)    
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

    -- Draw the border around the board
    love.graphics.setColor(0.55, 0.27, 0.07) -- Slightly browner border
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", boardStartX, boardStartY, squareSize * boardSize, squareSize * boardSize)

    -- Draw the chessboard
    for row = 1, boardSize do
        for col = 1, boardSize do
            local actualRow = isFlipped and (boardSize - row + 1) or row
            local actualCol = isFlipped and (boardSize - col + 1) or col
            local x = boardStartX + (col - 1) * squareSize
            local y = boardStartY + (row - 1) * squareSize

            if (actualRow + actualCol) % 2 == 0 then
                love.graphics.setColor(0.93, 0.81, 0.69) -- Beige squares
            else
                love.graphics.setColor(0.63, 0.32, 0.18) -- Brown squares
            end
            love.graphics.rectangle("fill", x, y, squareSize, squareSize)
        end
    end

    -- Highlight possible moves
    for _, move in ipairs(possibleMoves) do
        if move.row >= 1 and move.row <= boardSize and move.col >= 1 and move.col <= boardSize then
            local row = isFlipped and (boardSize - move.row + 1) or move.row
            local col = isFlipped and (boardSize - move.col + 1) or move.col
            local x = boardStartX + (col - 0.5) * squareSize
            local y = boardStartY + (row - 0.5) * squareSize

            local targetPiece = gameBoard:getPiece(move.row, move.col)

            if targetPiece and not targetPiece.name:find(gameBoard.currentTurn) then
                -- Capture move: draw a ring around the enemy piece
                love.graphics.setColor(0, 0, 0, 0.3) -- Semi-transparent black
                love.graphics.setLineWidth(5)
                love.graphics.circle("line", x, y, squareSize / 2 - 5)
            else
                -- Normal move: draw a semi-transparent dot
                love.graphics.setColor(0, 0, 0, 0.3) -- Semi-transparent black
                love.graphics.circle("fill", x, y, squareSize / 6)
            end
        end
    end


    -- Draw the coordinates outside the board
    love.graphics.setColor(0, 0, 0)
    for i = 1, boardSize do
        local file = files[i]
        local x = boardStartX + (i - 1) * squareSize + squareSize / 2 - 5
        local yTop = boardStartY - 20
        local yBottom = boardStartY + boardSize * squareSize + 5
        love.graphics.print(file, x, yTop)
        love.graphics.print(file, x, yBottom)

        local rank = tostring(isFlipped and i or (boardSize - i + 1))
        local y = boardStartY + (i - 1) * squareSize + squareSize / 2 - 7
        local xLeft = boardStartX - 20
        local xRight = boardStartX + boardSize * squareSize + 5
        love.graphics.print(rank, xLeft, y)
        love.graphics.print(rank, xRight, y)
    end

    -- Check if any king is in check
    local whiteKingInCheck = gameBoard:isKingInCheck("white")
    local blackKingInCheck = gameBoard:isKingInCheck("black")

    -- Draw the pieces
    for row = 1, boardSize do
        for col = 1, boardSize do
            local actualRow = isFlipped and (boardSize - row + 1) or row
            local actualCol = isFlipped and (boardSize - col + 1) or col
            local piece = gameBoard:getPiece(actualRow, actualCol)
            if piece and piece ~= selectedPiece then
                local x = boardStartX + (col - 0.5) * squareSize
                local y = boardStartY + (row - 0.5) * squareSize

                -- Check if the piece is a king in check
                local isKingInCheck = false
                if piece.name == "white_king" and whiteKingInCheck then
                    isKingInCheck = true
                elseif piece.name == "black_king" and blackKingInCheck then
                    isKingInCheck = true
                end

                if isKingInCheck then
                    -- Draw subtle red glow behind the king that fits inside the cell
                    local maxRadius = squareSize * 0.6 -- Slightly smaller than half the square size
                    local steps = 15 -- Fewer steps for a subtle effect
                    for i = 1, steps do
                        local radius = maxRadius * (i / steps)
                        local alpha = 0.5 * (1 - (i - 1) / steps)
                        love.graphics.setColor(1, 0, 0, alpha)
                        love.graphics.circle("fill", x, y, radius)
                    end
                end
                

                -- Draw the piece
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(
                    pieceImages[piece.name],
                    x,
                    y,
                    0, -- rotation
                    scaleFactor,
                    scaleFactor,
                    pieceImages[piece.name]:getWidth() / 2,
                    pieceImages[piece.name]:getHeight() / 2
                )
            end
        end
    end

    -- Draw the selected piece on top
    if selectedPiece then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            pieceImages[selectedPiece.name],
            selectedPiece.drawX,
            selectedPiece.drawY,
            0, -- rotation
            scaleFactor,
            scaleFactor,
            pieceImages[selectedPiece.name]:getWidth() / 2,
            pieceImages[selectedPiece.name]:getHeight() / 2
        )
    end

    -- Draw the flip button
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", flipButton.x, flipButton.y, flipButton.width, flipButton.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", flipButton.x, flipButton.y, flipButton.width, flipButton.height)
    love.graphics.printf(flipButton.text, flipButton.x, flipButton.y + 5, flipButton.width, "center")
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        -- Check if flip button was clicked
        if x >= flipButton.x and x <= flipButton.x + flipButton.width and
           y >= flipButton.y and y <= flipButton.y + flipButton.height then
            isFlipped = not isFlipped
            return
        end

        -- Convert mouse coordinates to board indices
        local col = math.floor((x - boardStartX) / squareSize) + 1
        local row = math.floor((y - boardStartY) / squareSize) + 1

        -- Check if the click is on the board
        if col >= 1 and col <= boardSize and row >= 1 and row <= boardSize then
            local actualRow = isFlipped and (boardSize - row + 1) or row
            local actualCol = isFlipped and (boardSize - col + 1) or col
            local piece = gameBoard:getPiece(actualRow, actualCol)
            if piece and piece.name:find(gameBoard.currentTurn) then
                selectedPiece = piece
                selectedPiece.origRow = actualRow
                selectedPiece.origCol = actualCol
                local mouseX, mouseY = love.mouse.getPosition()
                selectedPiece.drawX = mouseX
                selectedPiece.drawY = mouseY
                mouseOffsetX = selectedPiece.drawX - mouseX
                mouseOffsetY = selectedPiece.drawY - mouseY

                -- Get possible moves from gameBoard
                possibleMoves = gameBoard:getLegalMoves(actualRow, actualCol)
            else
                selectedPiece = nil
                possibleMoves = {}
            end
        else
            selectedPiece = nil
            possibleMoves = {}
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 and selectedPiece then
        -- Convert mouse coordinates to board indices
        local col = math.floor((x - boardStartX) / squareSize) + 1
        local row = math.floor((y - boardStartY) / squareSize) + 1

        -- Adjust for flipped board
        local actualRow = isFlipped and (boardSize - row + 1) or row
        local actualCol = isFlipped and (boardSize - col + 1) or col

        local fromRow = selectedPiece.origRow
        local fromCol = selectedPiece.origCol

        if gameBoard:movePiece(fromRow, fromCol, actualRow, actualCol) then
            -- Move was successful
        else
            -- Invalid move; no action needed since the piece wasn't removed from the board
        end

        selectedPiece = nil
        possibleMoves = {}
    end
end
