//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	private let statusCodeOK = 200
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] (result) in
			guard let `self` = self else { return }
			switch result {
			case .success((let data, let response)):
				self.handleSuccess(data: data, response: response, completion: completion)
			case .failure(_):
				completion(.failure(Error.connectivity))
			}
		}
	}

	private func handleSuccess(data: Data,
							   response: HTTPURLResponse,
							   completion: @escaping (FeedLoader.Result) -> Void) {
		// check for 200 status code
		if response.statusCode != statusCodeOK {
			completion(.failure(Error.invalidData))
		} else {
			// check for valid json format
			guard let items = try? JSONDecoder().decode(RemoteFeedResponse.self, from: data) else {
				completion(.failure(Error.invalidData))
				return
			}
			completion(.success(items.feedImages))
		}
	}
}

private struct RemoteFeedResponse: Decodable {
	let items: [RemoteFeedImage]

	var feedImages: [FeedImage] {
		return items.map { $0.toFeedImage() }
	}
}

private struct RemoteFeedImage: Decodable {
	let image_id: UUID
	let image_desc: String?
	let image_loc: String?
	let image_url: URL

	func toFeedImage() -> FeedImage {
		return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
	}
}
