//
//  NSManagedObjectContext+StorageContext.swift
//  StorageKit
//
//  Copyright (c) 2017 StorageKit (https://github.com/StorageKit)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import CoreData

extension NSManagedObjectContext: StorageIdentifiableContext {}

// MARK: - StorageDeletableContext
extension NSManagedObjectContext: StorageDeletableContext {
    
    public func delete<T: StorageEntityType>(_ entity: T) throws {
        try delete([entity])
    }
    
    public func delete<T: StorageEntityType>(_ entities: [T]) throws {
        entities.lazy
            .flatMap { $0 as? NSManagedObject }
            .forEach { delete($0) }
        
        guard hasChanges else { return }
        try save()
    }
    
    public func deleteAll<T: StorageEntityType>(_ entityType: T.Type) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.name)
        request.includesPropertyValues = false
        
        guard let result = try? fetch(request), let entries = result as? [NSManagedObject] else { return }
        entries.forEach { delete($0) }
        
        try save()
    }
}

// MARK: - StorageWritableContext
extension NSManagedObjectContext: StorageWritableContext {
    public func add<T: StorageEntityType>(_ entity: T) throws {
        try save()
    }
    
    public func add<T: StorageEntityType>(_ entities: [T]) throws {
        try save()
    }

    public func create<T: StorageEntityType>() -> T? {
        return NSEntityDescription.insertNewObject(forEntityName: T.name, into: self) as? T
    }
}

// MARK: - StorageUpdatableContext
extension NSManagedObjectContext: StorageUpdatableContext {
    
    public func update(transform: @escaping () -> Void) throws {
        transform()
        
        try save()
    }
}

// MARK: - StorageReadableContext
extension NSManagedObjectContext: StorageReadableContext {
	public func fetch<T: StorageEntityType>(predicate: NSPredicate? = nil, sortDescriptors: [SortDescriptor]? = nil, completion: @escaping FetchCompletionClosure<T>) {

		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.name)
		fetchRequest.predicate = predicate
        
        let sorts = sortDescriptors?.flatMap {  NSSortDescriptor(key: $0.key, ascending: $0.ascending) }
        fetchRequest.sortDescriptors = sorts

		let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in

			let result = asynchronousFetchResult.finalResult as? [T]

			DispatchQueue.main.async {
				completion(result)
			}
		}

		do {
			try execute(asynchronousFetchRequest)
		} catch let error {
			print("NSAsynchronousFetchRequest error: \(error)")
		}
	}
}
