_ = require 'underscore'
Buffer = require 'buffer'
Highlighter = require 'highlighter'

describe "screenLineFragment", ->
  [screenLine, highlighter] = []

  beforeEach ->
    buffer = new Buffer(require.resolve 'fixtures/sample.js')
    highlighter = new Highlighter(buffer)
    screenLine = highlighter.screenLineForRow(3)

  describe ".splitAt(column)", ->
    it "breaks the line fragment into two fragments", ->
      [left, right] = screenLine.splitAt(31)
      expect(left.text).toBe '    var pivot = items.shift(), '
      expect(tokensText left.tokens).toBe left.text

      expect(right.text).toBe 'current, left = [], right = [];'
      expect(tokensText right.tokens).toBe right.text

    it "splits tokens if they straddle the split boundary", ->
      [left, right] = screenLine.splitAt(34)
      expect(left.text).toBe '    var pivot = items.shift(), cur'
      expect(tokensText left.tokens).toBe left.text

      expect(right.text).toBe 'rent, left = [], right = [];'
      expect(tokensText right.tokens).toBe right.text

      expect(_.last(left.tokens).type).toBe right.tokens[0].type

    it "ensures the returned fragments cover the span of the original line", ->
      [left, right] = screenLine.splitAt(15)
      expect(left.bufferDelta).toEqual [0, 15]
      expect(left.screenDelta).toEqual [0, 15]

      expect(right.bufferDelta).toEqual [1, 0]
      expect(right.screenDelta).toEqual [1, 0]

      [left2, right2] = left.splitAt(5)
      expect(left2.bufferDelta).toEqual [0, 5]
      expect(left2.screenDelta).toEqual [0, 5]

      expect(right2.bufferDelta).toEqual [0, 10]
      expect(right2.screenDelta).toEqual [0, 10]

    describe "if splitting at 0", ->
      it "returns undefined for the left half", ->
        expect(screenLine.splitAt(0)).toEqual [undefined, screenLine]

    describe "if splitting at a column equal to the line length", ->
      it "returns an empty line fragment that spans a row for the right half", ->
        [left, right] = screenLine.splitAt(screenLine.text.length)

        expect(left.text).toBe screenLine.text
        expect(left.screenDelta).toEqual [0, screenLine.text.length]
        expect(left.bufferDelta).toEqual [0, screenLine.text.length]

        expect(right.text).toBe ''
        expect(right.screenDelta).toEqual [1, 0]
        expect(right.bufferDelta).toEqual [1, 0]

  describe ".concat(otherFragment)", ->
    it "returns the concatenation of the receiver and the given fragment", ->
      [left, right] = screenLine.splitAt(14)
      expect(left.concat(right)).toEqual screenLine

      concatenated = screenLine.concat(highlighter.screenLineForRow(4))
      expect(concatenated.text).toBe '    var pivot = items.shift(), current, left = [], right = [];    while(items.length > 0) {'
      expect(tokensText concatenated.tokens).toBe concatenated.text
      expect(concatenated.screenDelta).toEqual [2, 0]
      expect(concatenated.bufferDelta).toEqual [2, 0]





