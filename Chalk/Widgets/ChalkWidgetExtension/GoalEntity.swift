// GoalEntity.swift
// Chalk — Widget Extension
//
// AppEntity used by SelectGoalIntent so the user can pick a specific goal
// from the widget configuration sheet. Entity list is derived from the
// widget snapshot (post-refresh) or the raw categories key (pre-first-launch).

import AppIntents
import Foundation

struct GoalEntity: AppEntity {
    let id: String   // UUID string
    let name: String
    let icon: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }

    static var defaultQuery = GoalEntityQuery()
}

struct GoalEntityQuery: EntityQuery {

    func entities(for identifiers: [String]) async throws -> [GoalEntity] {
        allGoals().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [GoalEntity] {
        allGoals()
    }

    private func allGoals() -> [GoalEntity] {
        if let snapshot = loadSnapshot(), !snapshot.goals.isEmpty {
            return snapshot.goals.map { GoalEntity(id: $0.id.uuidString, name: $0.name, icon: $0.icon) }
        }
        return loadCategoryEntities()
    }

    private func loadSnapshot() -> WidgetSnapshot? {
        guard let store = UserDefaults(suiteName: SharedConstants.appGroupIdentifier),
              let data = store.data(forKey: SharedConstants.UserDefaultsKey.widgetSnapshot),
              let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return nil }
        return snap
    }

    // Fallback: decode only the fields we need from the categories UserDefaults entry.
    // WorkoutCategory isn't available in the widget target, so we use a lightweight struct.
    private func loadCategoryEntities() -> [GoalEntity] {
        guard let store = UserDefaults(suiteName: SharedConstants.appGroupIdentifier),
              let data = store.data(forKey: SharedConstants.UserDefaultsKey.categories),
              let cats = try? JSONDecoder().decode([CategoryInfo].self, from: data) else { return [] }
        return cats.map { GoalEntity(id: $0.id.uuidString, name: $0.name, icon: $0.icon) }
    }
}

private struct CategoryInfo: Decodable {
    let id: UUID
    let name: String
    let icon: String
}
