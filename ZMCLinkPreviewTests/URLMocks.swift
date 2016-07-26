//
//  URLMocks.swift
//  ZMCLinkPreview
//
//  Created by Silvan Dähn on 04.07.16.
//
//

import ZMCLinkPreview

class MockURLSessionDataTask: URLSessionDataTaskType {
    
    var taskIdentifier = 0
    var resumeCallCount = 0
    var cancelCallCount = 0
    var mockOriginalRequest: NSURLRequest? = nil
    
    var originalRequest: NSURLRequest? {
        return mockOriginalRequest
    }
    
    func resume() {
        resumeCallCount += 1
    }
    
    func cancel() {
        cancelCallCount += 1
    }
}

class MockURLSession: URLSessionType {
    
    var dataTaskWithURLCallCount = 0
    var dataTaskWithURLParameters = [NSURL]()
    var dataTaskWithURLClosureCallCount = 0
    var dataTaskWithURLClosureCompletions = [DataTaskCompletion]()
    var mockDataTask: MockURLSessionDataTask? = nil
    var dataTaskGenerator: ((NSURL, DataTaskCompletion) -> URLSessionDataTaskType)? = nil
    
    func dataTaskWithURL(url: NSURL) -> URLSessionDataTaskType {
        dataTaskWithURLCallCount += 1
        dataTaskWithURLParameters.append(url)
        return mockDataTask!
    }
    
    func dataTaskWithURL(url: NSURL, completionHandler: DataTaskCompletion) -> URLSessionDataTaskType {
        dataTaskWithURLClosureCallCount += 1
        dataTaskWithURLClosureCompletions.append(completionHandler)
        if let generator = dataTaskGenerator {
            return generator(url, completionHandler)
        } else {
            completionHandler(nil, nil, nil)
            return mockDataTask!
        }
    }
}
