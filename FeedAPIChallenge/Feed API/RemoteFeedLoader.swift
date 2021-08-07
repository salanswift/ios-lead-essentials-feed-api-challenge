//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in

			guard self != nil else { return }

			switch result {
			case let .success((data, response)):

				completion(FeedItemMapper.map(data, response: response))

			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}

internal final class FeedItemMapper {
	private struct Root: Decodable {
		let items: [Item]

		var feed: [FeedImage] {
			return items.map {
				$0.item
			}
		}
	}

	private struct Item: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		var item: FeedImage {
			return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
		}
	}

	static var OK_200: Int { return 200 }

	internal static func map(_ data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
		guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}

		return .success(root.feed)
	}
}
