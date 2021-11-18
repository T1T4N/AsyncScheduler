import XCTest
@testable import AsyncScheduler

#if canImport(Combine)
import Combine
#endif

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension TaskPriority {
    public static let all: [TaskPriority] = [.high, .medium, .low, .userInitiated, .utility, .background]
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
final class AsyncSchedulerTests: XCTestCase {
    func testNormal() async throws {
        let expectations = TaskPriority.all.map {
            (priority: $0, expectation: XCTestExpectation(description: "Execute with priority: \($0)"))
        }

        for pair in expectations {
            print("Testing priority: \(pair.priority)")
            AsyncScheduler.shared.schedule(options: .init(priority: pair.priority)) {
                withUnsafeCurrentTask { task in
                    guard let task = task else { return }
                    guard !task.isCancelled, task.priority == pair.priority else { return }
                    pair.expectation.fulfill()
                }
            }
        }

        wait(for: expectations.map { $0.expectation }, timeout: 0.1)
    }

    func testAfter() throws {
        let now = DispatchTime.now()
        let later = now + . milliseconds(500)

        let expectations = TaskPriority.all.map {
            (priority: $0, expectation: XCTestExpectation(description: "Execute after deadline with priority: \($0)"))
        }

        for pair in expectations {
            print("Testing priority: \(pair.priority)")

            AsyncScheduler.shared.schedule(after: .init(later), tolerance: .zero, options: .init(priority: pair.priority)) {
                withUnsafeCurrentTask { task in
                    guard let task = task else { return }
                    guard !task.isCancelled, task.priority == pair.priority else { return }
                    pair.expectation.fulfill()
                }
            }
        }

        wait(for: expectations.map { $0.expectation}, timeout: 1.0)
    }

    func testInterval() throws {
        let expectation = XCTestExpectation(description: "Execute interval")
        expectation.expectedFulfillmentCount = 5
        expectation.assertForOverFulfill = true

        let done = XCTestExpectation(description: "Done with execution")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(501)) {
            done.fulfill()
        }

        var bag: Set<AnyCancellable> = []
        AsyncScheduler.shared.schedule(after: DispatchQueue.SchedulerTimeType(.now()),
                                       interval: DispatchQueue.SchedulerTimeType.Stride(.milliseconds(100)),
                                       tolerance: .zero, options: nil) {
            expectation.fulfill()
        }
        .store(in: &bag)

        wait(for: [done, expectation], timeout: 1.0)
    }

    func testIntervalCancel() throws {
        let done = XCTestExpectation(description: "Done with execution")
        var count: Int32 = 0
        let expectedCount: Int32 = 5

        var bag: Set<AnyCancellable> = []
        AnyCancellable { done.fulfill() }
            .store(in: &bag)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(501)) {
            bag.removeAll()
        }

        AsyncScheduler.shared.schedule(after: DispatchQueue.SchedulerTimeType(.now()),
                                       interval: DispatchQueue.SchedulerTimeType.Stride(.milliseconds(100)),
                                       tolerance: .zero, options: nil) {
            OSAtomicIncrement32(&count)
        }
        .store(in: &bag)

        wait(for: [done], timeout: 1.0)
        XCTAssertEqual(count, expectedCount)
    }

    func testIntervalCombine() throws {
        let expectation = XCTestExpectation(description: "Execute interval")
        var count: Int32 = 0
        let expectedCount: Int32 = 5

        var bag: Set<AnyCancellable> = []
        (1...100).publisher
            // as AsyncScheduler is concurrent, values will not be received in order
            .receive(on: AsyncScheduler.shared, options: nil)
            .prefix(5)
            .eraseToAnyPublisher()
            .print()
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: {
                print($0)
                OSAtomicIncrement32(&count)
            })
            .store(in: &bag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(count, expectedCount)
    }
}
