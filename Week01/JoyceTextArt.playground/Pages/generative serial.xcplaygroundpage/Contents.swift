let firstSymbol = "*"
let secondSymbol = "-"
let thirdSymbol = "⭐️"
let combineSymbol = firstSymbol + secondSymbol

//method
func drawSymbol(count: Int, symbol: String) -> String {
    var line = ""
    if count <= 0 {
        return ""
    }
    for x in 1...count {
        line += symbol
    }
    return line
}

func triangle(height: Int, symbol: String) {
    for h in 1...height {
        
        print(drawSymbol(count: height-h, symbol: " ")+drawSymbol(count: h, symbol: symbol))
    }
}

//main
triangle(height: 3, symbol: "*" )
print(drawSymbol(count: 4, symbol: "-"))

triangle(height: 5, symbol: "⭐️" )
print(drawSymbol(count: 6, symbol: "-"))

triangle(height: 7, symbol: combineSymbol )
print(drawSymbol(count: 8, symbol: "-"))