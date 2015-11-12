//
//  NativeFeature.swift
//  Pods
//
//  Created by Sam Dean on 06/11/2015.
//
//

import Foundation

private struct FileTags {
    static let Feature = "Feature:"
    static let Scenario = "Scenario:"
    static let Outline = "Scenario Outline:"
    static let Examples = "Examples:"
    static let ExampleLine = "|"
    static let Given = "Given"
    static let When = "When"
    static let Then = "Then"
    static let And = "And"
}

class NativeFeature : CustomStringConvertible {
    let featureDescription: String
    let tags: [String]
    let scenarios: [NativeScenario]
    
    required init(description: String, tags:[String], scenarios:[NativeScenario]) {
        self.featureDescription = description
        self.tags = tags
        self.scenarios = scenarios
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType) \(self.featureDescription) \(self.scenarios.count) scenario(s)"
        }
    }
}

extension NativeFeature {
    
    convenience init?(contentsOfURL url: NSURL) {
        // Read in the file
        let contents = try! NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding)
        
        // Get all the lines in the file
        let lines = contents.componentsSeparatedByString("\n")
            .map { $0.stringByTrimmingCharactersInSet(whitespace) }
        
        guard lines.count > 0 else { return nil }
        
        // There is only one feature per file so we don't need these properties to be part of the ParseState object
        var featureDescription = ""
        var featureTags:[String] = []

        // Create the parser state, this will be built up and used to create each scenario
        var state = ParseState()
        var scenarios = Array<NativeScenario>()
        
        // Go through each line in turn
        for (lineIndex,line) in lines.enumerate() {
            
            if !line.isEmpty {
                // If this is a line of tags, record them and move on to the next line
                if let tags = line.toTags() {
                    state.tags = tags
                    continue
                }
                
                // What kind of line is it?
                if let (linePrefix, lineSuffix) = line.lineComponents() {
                    
                    switch(linePrefix) {
                    case FileTags.Feature:
                        featureDescription = lineSuffix
                        featureTags = state.tags
                        state = ParseState()
                        break
                        
                    case FileTags.Scenario:
                        if let newScenarios = state.scenarios() {
                            scenarios.appendContentsOf(newScenarios)
                        }
                        state = ParseState(description: lineSuffix)
                        
                    case FileTags.Given, FileTags.When, FileTags.Then, FileTags.And:
                        state.steps.append(lineSuffix)
                        
                    case FileTags.Outline:
                        if let newScenarios = state.scenarios() {
                            scenarios.appendContentsOf(newScenarios)
                        }
                        state = ParseState(description: lineSuffix)
                        
                    case FileTags.Examples:
                        // Prep the examples array for examples
                        state.exampleLines = []

                    case FileTags.ExampleLine:
                        state.exampleLines.append( (lineIndex+1, lineSuffix) )
                        
                    default:
                        // Just ignore lines we don't recognise yet
                        break
                    }
                    
                }
            }

        }
        
        // If we hit the end of the file, we need to make sure we have dealt with
        // the last scenarios
        if let newScenarios = state.scenarios() {
            scenarios.appendContentsOf(newScenarios)
        }
    
        self.init(description: featureDescription, tags:featureTags, scenarios:scenarios)
    }

}

private let whitespace = NSCharacterSet.whitespaceCharacterSet()

extension String {
    
    func componentsWithPrefix(prefix: String) -> (String, String?) {
        guard self.hasPrefix(prefix) else { return (self,nil) }
        
        let index = (prefix as NSString).length
        let suffix = (self as NSString).substringFromIndex(index).stringByTrimmingCharactersInSet(whitespace)
        return (prefix, suffix)
    }
    
    func lineComponents() -> (String, String)? {
        let prefixes = [ FileTags.Feature, FileTags.Scenario, FileTags.Given, FileTags.When, FileTags.Then, FileTags.And, FileTags.Outline, FileTags.Examples, FileTags.ExampleLine ]
        
        func first(a: [String]) -> (String, String)? {
            if a.count == 0 { return nil }
            let string = a.first!
            let (prefix, suffix) = self.componentsWithPrefix(string)
            if let suffix = suffix {
                return (prefix, suffix)
            } else {
                return first(Array(a.dropFirst(1)))
            }
        }
        
        return first(prefixes)
    }
    
    /**
        Takes a line and returns the tags from it
     
        - return: An array of tags, or nil if the string isn't a list of tags
     */
    func toTags() -> [String]? {
        guard self.stringByTrimmingCharactersInSet(whitespace).hasPrefix("@") else { return nil }
        
        return self.componentsSeparatedByString(",").map { $0.stringByTrimmingCharactersInSet(whitespace) }
    }
}
