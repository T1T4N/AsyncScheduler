//
//  AsyncScheduler.swift
//  AsyncScheduler
//
//  Created by Robert Armenski on 18.11.21.
//  Copyright © 2020 Robert Armenski. All rights reserved.
//

import Combine
import Dispatch

extension DispatchTimeInterval {
    internal var nanoseconds: UInt64 {
        switch self {
            case .seconds(let s):
                return UInt64(s) * NSEC_PER_SEC
            case .milliseconds(let ms):
                return UInt64(ms) * NSEC_PER_MSEC
            case .microseconds(let us):
                return UInt64(us) * NSEC_PER_USEC
            case .nanoseconds(let ns):
                return UInt64(ns)
            case .never:
                return UInt64.max
            @unknown default:
                fatalError()
        }
    }
}

/// A concurrent scheduler using Swift's new async/await features
/// Creates a new Task for each scheduled action
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public class AsyncScheduler: Scheduler {
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType

    public var now: SchedulerTimeType { .init(.now()) }
    public var minimumTolerance: SchedulerTimeType.Stride { .nanoseconds(0) }

    /// The shared instance of the immediate scheduler.
    ///
    /// You cannot create instances of the immediate scheduler yourself. Use only
    /// the shared instance.
    public static let shared = AsyncScheduler()

    public func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        let now = DispatchTime.now().rawValue
        let after = date.dispatchTime.rawValue
        let diff = after >= now ? after - now : now - after
        let timeInterval = interval.timeInterval

        let top = Task(priority: options?.priority) {
            // sleep until date
            await Task.sleep(diff)

            while true {
                await self.schedule(options, action)
                await Task.sleep(timeInterval.nanoseconds)
                guard !Task.isCancelled else { break }
            }
        }

        return AnyCancellable { top.cancel() }
    }

    public func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?, _ action: @escaping () -> Void) {
        let now = DispatchTime.now().rawValue
        let after = date.dispatchTime.rawValue
        let diff = after >= now ? after - now : now - after

        Task(priority: options?.priority) {
            // sleep until date
            await Task.sleep(diff)
            await self.schedule(options, action)
        }
    }

    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        Task(priority: options?.priority) {
            await self.schedule(options, action)
        }
    }

    func schedule(_ options: SchedulerOptions?, _ action: @escaping () -> Void) async {
        action()
    }

}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension AsyncScheduler {
    /// Options that affect the operation of the dispatch queue scheduler.
    public struct SchedulerOptions {

        /// The task priority.
        public var priority: TaskPriority?

        public init(priority: TaskPriority? = nil) {
            self.priority = priority
        }
    }
}
