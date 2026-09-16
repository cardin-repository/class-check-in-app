import SwiftUI

struct CheckIn: Identifiable {
    let id = UUID()
    let name: String
    let className: String
    let time: Date
}

struct ContentView: View {
    @State private var name = ""
    @State private var className = ""
    @State private var checkIns: [CheckIn] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Check in to class") {
                    TextField("Your name", text: $name)

                    TextField("Class name", text: $className)

                    Button("Check In") {
                        addCheckIn()
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        className.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }

                Section("Recent check-ins") {
                    if checkIns.isEmpty {
                        Text("No one has checked in yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(checkIns) { checkIn in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checkIn.name)
                                    .font(.headline)

                                Text(checkIn.className)
                                    .font(.subheadline)

                                Text(
                                    "Checked in at \(checkIn.time.formatted(date: .omitted, time: .shortened))"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Class Check-In")
        }
    }

    private func addCheckIn() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClassName = className.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedClassName.isEmpty else {
            return
        }

        let newCheckIn = CheckIn(
            name: trimmedName,
            className: trimmedClassName,
            time: Date()
        )

        checkIns.insert(newCheckIn, at: 0)

        name = ""
        className = ""
    }
}

#Preview {
    ContentView()
}
