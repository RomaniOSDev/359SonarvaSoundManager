import SwiftUI
import UIKit

extension View {
    func vinylCanvas() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground").overlay {
                    Image("bg_vinyl").resizable().scaledToFill().opacity(0.34)
                }.clipped().ignoresSafeArea()
            }
    }

    func studioNavChrome() -> some View {
        self
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }

    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardTapModifier())
    }

    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(Color("AppPrimary"))
            }
        }
    }
}

private struct DismissKeyboardTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(DismissKeyboardTapView())
    }
}

private struct DismissKeyboardTapView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject {
        @objc func handleTap() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
