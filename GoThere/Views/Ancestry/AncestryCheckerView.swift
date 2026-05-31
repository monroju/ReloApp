import SwiftUI

struct AncestryCheckerView: View {
    private let repo = AncestryRepository.shared
    @State private var selectedPath: AncestryPath?
    @State private var ruleAnswers: [String: Bool] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let path = selectedPath {
                    detail(for: path)
                } else {
                    countryPicker
                    disclaimer
                }
            }
            .padding()
        }
        .navigationTitle("Ancestry Citizenship")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.goBackgroundLight.opacity(0.4))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You might already be a citizen.")
                .font(.title2.bold())
                .foregroundColor(.goPrimary)
            Text("Six EU countries pass citizenship down to grandchildren or further. No income test, no residency requirement, no language test (mostly). The hardest part is the paperwork.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Upper-tier "second passport / Plan B" framing — the same route a CBI buyer
            // pays $200k+ for, available for the cost of document research if you qualify.
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.goPrimary)
                Text("A second passport for the cost of paperwork. What investors pay $200k+ for via citizenship-by-investment, you may inherit — full EU mobility, a tax-residency option, and a real Plan B.")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.goPrimary.opacity(0.08))
            .cornerRadius(10)
        }
    }

    private var countryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick the ancestor's country").font(.headline)
            ForEach(repo.paths) { path in
                Button {
                    selectedPath = path
                    ruleAnswers = [:]
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(path.countryName).font(.body.bold()).foregroundColor(.primary)
                            Text(path.shortName).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var disclaimer: some View {
        Text(repo.catalog.disclaimer)
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.top, 12)
    }

    private func detail(for path: AncestryPath) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                selectedPath = nil
            } label: {
                Label("Back to countries", systemImage: "chevron.left")
                    .font(.caption)
                    .foregroundColor(.goPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(path.fullName).font(.title3.bold())
                Text(path.summary).font(.body).foregroundColor(.secondary)
            }

            quickStats(path)
            eligibilitySection(path)
            verdictSection(path)
            documentsSection(path)
            lowIncomeSection(path)
            officialLinkSection(path)
        }
    }

    private func quickStats(_ path: AncestryPath) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Cost", value: "$\(path.estCostUSD.low)–$\(path.estCostUSD.high)")
            statCard(title: "Timeline", value: "\(path.estTimelineMonths.low)–\(path.estTimelineMonths.high) mo")
            statCard(title: "Income test", value: path.incomeRequired ? "Yes" : "None")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private func eligibilitySection(_ path: AncestryPath) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Do you qualify?").font(.headline)
            ForEach(path.eligibilityRules) { rule in
                ruleRow(rule: rule)
            }
        }
    }

    private func ruleRow(rule: AncestryPath.EligibilityRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(rule.label).font(.subheadline)
                Spacer()
                Picker("", selection: Binding(
                    get: { ruleAnswers[rule.id] },
                    set: { ruleAnswers[rule.id] = $0 }
                )) {
                    Text("?").tag(Optional<Bool>.none)
                    Text("Yes").tag(Optional<Bool>.some(true))
                    Text("No").tag(Optional<Bool>.some(false))
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            if let explanation = rule.explanation {
                Text(explanation).font(.caption).foregroundColor(.secondary)
            }
            if let workaround = rule.openWorkaround, ruleAnswers[rule.id] == false {
                Text("Workaround available: \(workaround)")
                    .font(.caption.bold())
                    .foregroundColor(.goPrimary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private func verdictSection(_ path: AncestryPath) -> some View {
        let required = path.eligibilityRules.filter { $0.required }
        let answered = required.allSatisfy { ruleAnswers[$0.id] != nil }
        let allYes = required.allSatisfy { ruleAnswers[$0.id] == true }

        return Group {
            if answered {
                VStack(alignment: .leading, spacing: 6) {
                    if allYes {
                        Text("Likely eligible ✓")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text(path.outcome).font(.subheadline)
                    } else {
                        Text("Direct path blocked")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("One or more required rules failed. Check the workaround notes above — some failed rules have court-petition paths that still work.")
                            .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(allYes ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private func documentsSection(_ path: AncestryPath) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Documents you'll need").font(.headline)
            ForEach(path.documents, id: \.self) { doc in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "doc.text").foregroundColor(.goPrimary).font(.caption)
                    Text(doc).font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func lowIncomeSection(_ path: AncestryPath) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("If money is tight").font(.headline)
            Text(path.lowIncomeNotes).font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.goPrimary.opacity(0.08))
        .cornerRadius(12)
    }

    private func officialLinkSection(_ path: AncestryPath) -> some View {
        if let url = URL(string: path.officialUrl) {
            return AnyView(Link(destination: url) {
                Label("Official government source", systemImage: "arrow.up.right.square")
                    .font(.subheadline.bold())
                    .foregroundColor(.goPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12))
        }
        return AnyView(EmptyView())
    }
}
