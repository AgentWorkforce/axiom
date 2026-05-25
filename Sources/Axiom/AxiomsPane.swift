import SwiftUI
import AxiomCore

struct AxiomsPane: View {
    @EnvironmentObject var model: AxiomViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(AxiomCategory.allCases) { category in
                    CategorySection(category: category)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

private struct CategorySection: View {
    @EnvironmentObject var model: AxiomViewModel
    let category: AxiomCategory

    var body: some View {
        let items = model.document.axioms(in: category)

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(category.title, systemImage: category.systemImage)
                    .font(.title3.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                Spacer()
                Button {
                    model.add(category: category)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add a \(category.singular.lowercased())")
            }
            Text(category.blurb)
                .font(.callout)
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text("No \(category.title.lowercased()) yet.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { axiom in
                        AxiomRow(axiom: axiom)
                        if axiom.id != items.last?.id {
                            Divider().padding(.leading, 38)
                        }
                    }
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )
            }
        }
    }
}

private struct AxiomRow: View {
    @EnvironmentObject var model: AxiomViewModel
    let axiom: Axiom
    @State private var draft: String = ""
    @FocusState private var editing: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                model.toggleApproved(axiom)
            } label: {
                Image(systemName: axiom.approved ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(axiom.approved ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(axiom.approved ? "Approved — click to unapprove" : "Approve this axiom")

            TextField("", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($editing)
                .onAppear { draft = axiom.text }
                .onChange(of: editing) { isEditing in
                    if !isEditing, draft != axiom.text {
                        model.updateText(axiom, to: draft)
                    }
                }
                .onSubmit {
                    model.updateText(axiom, to: draft)
                    editing = false
                }
                .foregroundStyle(axiom.approved ? .primary : .secondary)

            Spacer(minLength: 4)

            Menu {
                Button("Move up") { model.moveUp(axiom) }
                    .keyboardShortcut(.upArrow, modifiers: [.command])
                Button("Move down") { model.moveDown(axiom) }
                    .keyboardShortcut(.downArrow, modifiers: [.command])
                Divider()
                Section("Move to category") {
                    ForEach(AxiomCategory.allCases) { cat in
                        Button {
                            model.setCategory(axiom, to: cat)
                        } label: {
                            Label(cat.singular, systemImage: cat.systemImage)
                        }
                        .disabled(cat == axiom.category)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26)
            .help("Reorder or move to another category")

            Button(role: .destructive) {
                model.delete(axiom)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Delete")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
