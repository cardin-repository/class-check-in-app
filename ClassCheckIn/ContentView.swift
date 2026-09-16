import SwiftUI

struct CheckIn: Identifiable, Codable {
    let id: Int
    let name: String
    let className: String
    let time: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case className = "class_name"
        case time
    }
}

struct CheckInRequest: Codable {
    let name: String
    let className: String

    enum CodingKeys: String, CodingKey {
        case name
        case className = "class_name"
    }
}

struct ContentView: View {
    @State private var name = ""
    @State private var className = ""
    @State private var checkIns: [CheckIn] = []

    @State private var isLoading = false
    @State private var errorMessage: String?

    private let baseURL = "http://127.0.0.1:8000"

    var body: some View {
        NavigationStack {
            Form {
                Section("Check in to class") {
                    TextField("Your name", text: $name)

                    TextField("Class name", text: $className)

                    Button("Check In") {
                        Task {
                            await submitCheckIn()
                        }
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        className.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        isLoading
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Recent check-ins") {
                    if isLoading && checkIns.isEmpty {
                        ProgressView("Loading check-ins...")
                    } else if checkIns.isEmpty {
                        Text("No one has checked in yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(checkIns) { checkIn in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checkIn.name)
                                    .font(.headline)

                                Text(checkIn.className)
                                    .font(.subheadline)

                                Text("Checked in at \(formattedTime(checkIn.time))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Class Check-In")
            .task {
                await loadCheckIns()
            }
            .refreshable {
                await loadCheckIns()
            }
        }
    }

    private func loadCheckIns() async {
        guard let url = URL(string: "\(baseURL)/checkins") else {
            errorMessage = "Invalid server URL."
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "The server returned an error."
                return
            }

            let decodedCheckIns = try JSONDecoder().decode(
                [CheckIn].self,
                from: data
            )

            checkIns = decodedCheckIns

        } catch {
            errorMessage = "Could not load check-ins: \(error.localizedDescription)"
        }
    }

    private func submitCheckIn() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClassName = className.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedClassName.isEmpty else {
            return
        }

        guard let url = URL(string: "\(baseURL)/checkins") else {
            errorMessage = "Invalid server URL."
            return
        }

        let requestBody = CheckInRequest(
            name: trimmedName,
            className: trimmedClassName
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            errorMessage = "Could not prepare the check-in."
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "The server could not create the check-in."
                return
            }

            name = ""
            className = ""

            await loadCheckIns()

        } catch {
            errorMessage = "Could not submit check-in: \(error.localizedDescription)"
        }
    }

    private func formattedTime(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()

        if let date = formatter.date(from: value) {
            return date.formatted(
                date: .omitted,
                time: .shortened
            )
        }

        return value
    }
}

#Preview {
    ContentView()
}
