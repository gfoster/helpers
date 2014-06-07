extension String {
    subscript (r: Range<Int>) -> String {
        get {
            assert(r.startIndex <= r.endIndex, "end cannot exceed start")
            assert(r.startIndex >= 0, "start cannot be non-negative")
            assert(r.endIndex <= countElements(self), "end cannot exceed max length of string")
            return self.substringWithRange(
                Range(start: advance(self.startIndex, r.startIndex),
                    end: advance(self.startIndex, r.endIndex)))
        }
    }
}
// var s = "apple12345"
// println s[3..5]

