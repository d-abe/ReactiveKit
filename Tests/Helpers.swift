//
//  Common.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

extension EventType {

  func isEqualTo<E: EventType where E.Element == Element>(_ event: E) -> Bool {

    if self.isCompletion && event.isCompletion {
      return true
    } else if self.isFailure && event.isFailure {
      return true
    } else if let left = self.element, let right = event.element {
      if let left = left as? Int, let right = right as? Int {
        return left == right
      } else if let left = left as? [Int], let right = right as? [Int] {
        return left == right
      } else if let left = left as? (Int?, Int), let right = right as? (Int?, Int) {
        return left.0 == right.0 && left.1 == right.1
      } else if let left = left as? String, let right = right as? String {
        return left == right
      } else if let left = left as? [String], let right = right as? [String] {
        return left == right
      } else if let left = left as? CollectionChangeset<[Int]>, let right = right as? CollectionChangeset<[Int]> {
        return left.collection == right.collection && left.inserts == right.inserts && left.updates == right.updates && left.deletes == right.deletes
      } else if let left = left as? CollectionChangeset<[(String, Int)]>, let right = right as? CollectionChangeset<[(String, Int)]> {
        return left.collection == right.collection && left.inserts == right.inserts && left.updates == right.updates && left.deletes == right.deletes
      } else {
        fatalError("Cannot compare that element type. \(left)")
      }
    } else {
      return false
    }
  }
}

extension _StreamType {

  func expectNext(_ expectedElements: [Event.Element],  _ message: @autoclosure () -> String = "", expectation: XCTestExpectation? = nil, file: StaticString = #file, line: UInt = #line) {
    expect(expectedElements.map { Event.next($0) } + [Event.completed()], message, expectation: expectation, file: file, line: line)
  }

  func expect(_ expectedEvents: [Event], _ message: @autoclosure () -> String = "", expectation: XCTestExpectation? = nil, file: StaticString = #file, line: UInt = #line) {
    var eventsToProcess = expectedEvents
    var receivedEvents: [Event] = []
    let message = message()
    let _ = observe { event in
      receivedEvents.append(event)
      if eventsToProcess.count == 0 {
        XCTFail("Got more events then expected.")
        return
      }
      let expected = eventsToProcess.removeFirst()
      XCTAssert(event.isEqualTo(expected), message + "(Got \(receivedEvents) instead of \(expectedEvents))", file: file, line: line)
      if event.isTermination {
        expectation?.fulfill()
      }
    }
  }
}

class Scheduler {
  fileprivate var availableRuns = 0
  fileprivate var scheduledBlocks: [() -> Void] = []
  fileprivate(set) var numberOfRuns = 0

  func context(block: () -> Void) {
    self.scheduledBlocks.append(block)
    tryRun()
  }

  func runOne() {
    guard availableRuns < Int.max else { return }
    availableRuns += 1
    tryRun()
  }

  func runRemaining() {
    availableRuns += Int.max
    tryRun()
  }

  fileprivate func tryRun() {
    while  availableRuns > 0 && scheduledBlocks.count > 0 {
      let block = scheduledBlocks.removeFirst()
      block()
      numberOfRuns += 1
      availableRuns -= 1
    }
  }
}

func ==(lhs: [(String, Int)], rhs: [(String, Int)]) -> Bool {
  if lhs.count != rhs.count {
    return false
  }

  return zip(lhs, rhs).reduce(true) { memo, new in
    memo && new.0.0 == new.1.0 && new.0.1 == new.1.1
  }
}

