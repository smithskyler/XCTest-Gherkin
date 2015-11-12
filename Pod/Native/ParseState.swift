//
//  ParseState.swift
//  Pods
//
//  Created by Sam Dean on 09/11/2015.
//
//

import Foundation

private let whitespace = NSCharacterSet.whitespaceCharacterSet()

class ParseState: CustomDebugStringConvertible {
    var description: String?
    var steps: [String]
    var exampleLines: [ (lineNumber:Int, line:String) ]
    var tags: [String]
    
    convenience init() {
        self.init(description: nil)
    }
    
    required init(description: String?, tags: [String] = []) {
        self.description = description
        self.steps = []
        self.exampleLines = []
        self.tags = tags
    }
    
    private var examples:[NativeExample] {
        get {
            if self.exampleLines.count < 2 { return [] }
            
            var examples:[NativeExample] = []
            
            // The first line is the titles
            let titles = self.exampleLines.first!.line.componentsSeparatedByString("|").map { $0.stringByTrimmingCharactersInSet(whitespace) }
            
            // The other lines are the examples themselves
            self.exampleLines.dropFirst(1).forEach { rawLine in
                let line = rawLine.line.componentsSeparatedByString("|").map { $0.stringByTrimmingCharactersInSet(whitespace) }
                
                var pairs:[String:String] = Dictionary()
                
                (0..<titles.count).forEach { n in
                    // Get the title and value for this column
                    let title = titles[n]
                    let value = line.count > n ? line[n] : ""
                    
                    pairs[title] = value
                }
                
                examples.append( (rawLine.lineNumber, pairs ) )
            }
            
            return examples
        }
    }
    
    func scenarios() -> [NativeScenario]? {
        //print("Attempting to get scenarios from \(self.debugDescription)")
        
        guard let d = self.description else { return nil }
        guard self.steps.count > 0 else { return nil }
        
        var scenarios = Array<NativeScenario>()
        
        // If we have examples then we need to make more than one scenario
        if self.examples.count > 0 {
            // Replace each matching placeholder in each line with the example data
            self.examples.forEach { example in
                
                // This hoop is beacuse the compiler doesn't seem to
                // recognize mapdirectly on the state.steps object
                var steps = self.steps
                steps = self.steps.map { originalStep in
                    var step = originalStep
                    
                    example.pairs.forEach { (title, value) in
                        step = step.stringByReplacingOccurrencesOfString("<\(title)>", withString: value)
                    }
                    
                    return step
                }
                
                // The scenario description must be unique
                let description = "\(d)_line\(example.lineNumber)"
                scenarios.append(NativeScenario(description, steps: steps, tags: self.tags))
                
            }
        } else {
            scenarios.append(NativeScenario(d, steps: self.steps, tags: self.tags))
        }
        
        self.description = nil
        self.steps = []
        self.exampleLines = []
        self.tags = []
        
        return scenarios
    }
    
    var debugDescription: String {
        get {
            return "<\(self.dynamicType) '\(description)' \(steps.count) steps, \(exampleLines.count) examples, tags:'\(tags.joinWithSeparator(", "))'  >"
        }
    }
}
