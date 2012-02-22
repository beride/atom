_ = require 'underscore'
ScreenLineFragment = require 'screen-line-fragment'
EventEmitter = require 'event-emitter'

module.exports =
class Highlighter
  buffer: null
  tokenizer: null
  screenLines: []

  constructor: (@buffer) ->
    @buildTokenizer()
    @screenLines = @buildScreenLinesForRows('start', 0, @buffer.lastRow())
    @buffer.on 'change', (e) => @handleBufferChange(e)

  buildTokenizer: ->
    Mode = require("ace/mode/#{@buffer.modeName()}").Mode
    @tokenizer = (new Mode).getTokenizer()

  handleBufferChange: (e) ->
    oldRange = e.oldRange.copy()
    newRange = e.newRange.copy()
    previousState = @screenLines[oldRange.end.row].state # used in spill detection below

    startState = @screenLines[newRange.start.row - 1]?.state or 'start'
    @screenLines[oldRange.start.row..oldRange.end.row] =
      @buildScreenLinesForRows(startState, newRange.start.row, newRange.end.row)

    # spill detection
    # compare scanner state of last re-highlighted line with its previous state.
    # if it differs, re-tokenize the next line with the new state and repeat for
    # each line until the line's new state matches the previous state. this covers
    # cases like inserting a /* needing to comment out lines below until we see a */
    for row in [newRange.end.row...@buffer.lastRow()]
      break if @screenLines[row].state == previousState
      nextRow = row + 1
      previousState = @screenLines[nextRow].state
      @screenLines[nextRow] = @buildScreenLineForRow(@screenLines[row].state, nextRow)

    # if highlighting spilled beyond the bounds of the textual change, update
    # the pre and post range to reflect area of highlight changes
    if nextRow > newRange.end.row
      oldRange.end.row += (nextRow - newRange.end.row)
      newRange.end.row = nextRow
      endColumn = @buffer.getLine(nextRow).length
      newRange.end.column = endColumn
      oldRange.end.column = endColumn

    @trigger("change", {oldRange, newRange})

  buildScreenLinesForRows: (startState, startRow, endRow) ->
    state = startState
    for row in [startRow..endRow]
      screenLine = @buildScreenLineForRow(state, row)
      state = screenLine.state
      screenLine

  buildScreenLineForRow: (state, row) ->
    line = @buffer.getLine(row)
    {tokens, state} = @tokenizer.getLineTokens(line, state)
    new ScreenLineFragment(tokens, line, [1, 0], [1, 0], { state })

  screenLineForRow: (row) ->
    @screenLines[row]

  screenLinesForRows: (startRow, endRow) ->
    @screenLines[startRow..endRow]

  lastRow: ->
    @screenLines.length - 1

_.extend(Highlighter.prototype, EventEmitter)
