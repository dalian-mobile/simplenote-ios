import Foundation
import SimplenoteFoundation
import SimplenoteSearch
import CoreData

class WidgetDataController {

    /// Data Controller
    ///
    let managedObjectContext: NSManagedObjectContext

    /// Initialization
    ///
    init(context: NSManagedObjectContext, isPreview: Bool = false) throws {
        if !isPreview {
            guard WidgetDefaults.shared.loggedIn else {
                throw WidgetError.appConfigurationError
            }
        }

        self.managedObjectContext = context
    }

    // MARK: Public Methods

    /// Fetch notes with given tag and limit
    /// If no tag is specified, will fetch notes that are not deleted. If there is no limit specified it will fetch all of the notes
    ///
    func notes(filteredBy filter: TagsFilter = .allNotes, limit: Int = .zero) -> [Note]? {
        let request: NSFetchRequest<Note> = fetchRequest(filteredBy: filter, limit: limit)
        return performFetch(from: request)
    }

    func performFetch<T: NSManagedObject>(from request: NSFetchRequest<T>) -> [T]? {
        do {
            let objects = try managedObjectContext.fetch(request)
            return objects
        } catch {
            NSLog("Couldn't fetch objects: %@", error.localizedDescription)
            return nil
        }
    }

    /// Returns note given a simperium key
    ///
    func note(forSimperiumKey key: String) -> Note? {
        return notes()?.first { note in
            note.simperiumKey == key
        }
    }

    func firstNote() -> Note? {
        let fetched = notes(limit: 1)
        return fetched?.first
    }

    /// Creates a predicate for notes given a tag name.  If not specified the predicate is for all notes that are not deleted
    ///
    private func predicateForNotes(filteredBy tagFilter: TagsFilter = .allNotes) -> NSPredicate {
        switch tagFilter {
        case .allNotes:
            return NSPredicate.predicateForNotes(deleted: false)
        case .tag(let tag):
            return NSPredicate.predicateForNotes(tag: tag)
        }
    }

    private func sortDescriptorForNotes() -> NSSortDescriptor {
        return NSSortDescriptor.descriptorForNotes(sortMode: WidgetDefaults.shared.sortMode)
    }

    private func fetchRequest<T: NSManagedObject>(filteredBy filter: TagsFilter = .allNotes, limit: Int = .zero) -> NSFetchRequest<T> {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)
        fetchRequest.fetchLimit = limit
        fetchRequest.sortDescriptors = [sortDescriptorForNotes()]
        fetchRequest.predicate = predicateForNotes(filteredBy: filter)

        return fetchRequest
    }

    private func tagsFetchRequest() -> NSFetchRequest<Tag> {
        let fetchRequest = NSFetchRequest<Tag>(entityName: Tag.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor.descriptorForTags()]

        return fetchRequest
    }

    // MARK: - Tags

    func tags() -> [Tag]? {
        performFetch(from: tagsFetchRequest())
    }
}

enum TagsFilter {
    case allNotes
    case tag(String)
}

extension TagsFilter {
    init(from tag: String) {
        switch tag {
        case WidgetConstants.allNotesIdentifier:
            self = .allNotes
        default:
            self = .tag(tag)
        }
    }
}
