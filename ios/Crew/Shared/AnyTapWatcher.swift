// SPEC: A23 · docs/education-copy-draft.md §A rule 4 ("the first tap anywhere on that screen clears it") — HOW the app hears a tap
// without ever taking one. The first build did it with a SwiftUI `.simultaneousGesture(TapGesture())` on the root view, and CI run
// 35340692297 showed what that costs on a List: with the gesture installed, a tap on a NavigationLink row selected NOTHING —
// Settings' profile row, "Blocked people" and "Pause my plan" all stayed shut (ProfilePhotoDeniedTests and three tour steps), with or
// without a whisper showing. The root gesture recognised the tap and the List's own row selection was cancelled.
// So the listener is a PASSIVE UIKit recogniser on the window instead: it cancels no touch, delays no touch and recognises alongside
// every other recogniser — the recipe every SwiftUI app uses to dismiss a keyboard on any tap. It sees sheets too (they share the
// window), which is harmless: a whisper never renders in a sheet (rule 3). A tap that lands on a UIKit control (a tab-bar button, a
// switch) is the control's alone by UIKit's own rule, so it does not clear a whisper; the next tap on anything else does.
// The callback runs one main-queue turn AFTER the tap, so the row that leaves the screen never changes a List in the middle of the
// touch that is selecting another row. No view of its own: the carrier view takes no touches and draws nothing.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI
import UIKit

struct AnyTapWatcher: UIViewRepresentable {
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> CarrierView {
        let view = CarrierView()
        view.isUserInteractionEnabled = false
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: CarrierView, context: Context) {}

    // Lives in the hierarchy only to learn which window it is in
    final class CarrierView: UIView {
        var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { coordinator?.attach(to: window) }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let onTap: () -> Void
        private weak var attachedTo: UIWindow?

        init(onTap: @escaping () -> Void) { self.onTap = onTap }

        func attach(to window: UIWindow) {
            guard attachedTo !== window else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            attachedTo = window
        }

        @objc private func tapped() {
            DispatchQueue.main.async { self.onTap() }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
