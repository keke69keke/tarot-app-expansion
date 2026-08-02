import SwiftUI
import TarotCore

// MARK: - ReadingHistoryView
struct ReadingHistoryView: View {
    @StateObject private var viewModel: TarotReadingViewModel

    init(drawCardsUseCase: DrawCardsUseCaseProtocol) {
        _viewModel = StateObject(wrappedValue: TarotReadingViewModel(drawCardsUseCase: drawCardsUseCase))
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.drawnCards.isEmpty && !viewModel.isLoading {
                    Text("No readings saved yet.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading) {
                        Text("Last Reading: \(viewModel.spreadName)")
                            .font(.headline)
                        Text("Summary: \(viewModel.synthesisSummary)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(12)
                }

                List {
                    Section("Reading History") {
                        if viewModel.drawnCards.isEmpty && !viewModel.isLoading {
                            Text("No readings found.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.drawnCards) { drawnCard in
                                NavigationLink(destination: ReadingDetailView(drawnCard: drawnCard)) {
                                    HStack {
                                        Text("\(drawnCard.card.name)")
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("(\(drawnCard.position.type.rawValue))")
                                            .font(.caption)
                                            .foregroundStyle(.indigo)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reading History")
        }
    }
}

// MARK: - Detail View
struct ReadingDetailView: View {
    let drawnCard: DrawnCard

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)

            VStack {
                Text(drawnCard.card.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: drawnCard.orientation == .upright ? "arrowtriangle.up" : "arrowtriangle.down")
                        .foregroundStyle(drawnCard.orientation == .reversed ? Color.red : Color.green)
                        .font(.largeTitle)
                    Text("(\(drawnCard.orientation.rawValue))")
                        .font(.title2)
                }
            }

            VStack(alignment: .leading) {
                Text("Position Role:")
                    .font(.headline)
                Text(drawnCard.position.name)
                    .font(.subheadline)
                    .foregroundStyle(.indigo)

                Divider()

                Text("Interpretation:")
                    .font(.headline)
                // Use the positional interpretation if available, otherwise fall back to general meaning
                Text(drawnCard.positionalInterpretation ?? drawnCard.card.generalInterpretation)
                    .padding(10)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(8)
            }

        }
        .padding()
    }
}


// MARK: - Preview Provider (For Xcode Canvas)
struct ReadingHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        // To preview this view, we must provide a concrete implementation of the UseCase protocol.
        let mockUseCase = DrawCardsUseCaseImpl(cardRepository: CardRepositoryImpl(), synthesizer: SpreadSynthesizerImpl())
        return ReadingHistoryView(drawCardsUseCase: mockUseCase)
    }
}
